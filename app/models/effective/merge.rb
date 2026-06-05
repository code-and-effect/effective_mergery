module Effective
  class Merge
    include ActiveModel::Model

    attr_accessor :current_user
    attr_accessor :source_type, :source_id
    attr_accessor :target_type, :target_id

    validates :target_id, presence: true
    validates :target_type, presence: true

    validates :source_id, presence: true
    validates :source_type, presence: true

    validate(if: -> { source.present? && target.present? }) do
      errors.add(:base, "must be the same type") unless target.class == source.class
      errors.add(:target_id, "can't be the same record") if target.id == source.id
    end

    # Both records must be fully valid before we start moving anything
    validate(if: -> { source.present? }) do
      errors.add(:source_id, "is invalid: #{source.errors.full_messages.to_sentence}") unless source.valid?
    end

    validate(if: -> { target.present? }) do
      errors.add(:target_id, "is invalid: #{target.errors.full_messages.to_sentence}") unless target.valid?
    end

    def to_s
      (source.present? && target.present?) ? "Merge of #{source} to #{target}" : "New Merge"
    end

    def source
      @source ||= source_type.try(:safe_constantize).try(:find_by_id, source_id)
    end

    def source=(resource)
      raise('expected an ActiveRecord::Base resource') unless resource.is_a?(ActiveRecord::Base)
      assign_attributes(source_type: resource.class.name, source_id: resource.id)
      @source = resource
    end

    def target
      @target ||= target_type.try(:safe_constantize).try(:find_by_id, target_id)
    end

    def target=(resource)
      raise('expected an ActiveRecord::Base resource') unless resource.is_a?(ActiveRecord::Base)
      assign_attributes(target_type: resource.class.name, target_id: resource.id)
      @target = resource
    end

    def new_record?
      true
    end

    def save!
      merge!
    end

    def merge!(validate: true)
      raise ActiveRecord::RecordInvalid.new(self) unless valid?

      Rails.application.eager_load! unless Rails.application.config.eager_load

      klasses = defined?(Tenant) ? Tenant.klasses : ActiveRecord::Base.descendants.reject(&:abstract_class?)
      klasses = klasses.select { |klass| klass.table_exists? }

      success = false

      EffectiveResources.transaction do
        # Re-point every record that belongs to the source onto the target, treating the target as the
        # authoritative account. We walk from the belongs_to side so we catch foreign keys no has_many/has_one
        # is declared for - polymorphic owners (Effective::Address, Effective::EventRegistration) and named
        # self-refs alike (advisor_id, endorser_id, reviewer_id) - and move them with update_all. No per-record
        # validations or callbacks run, so historical data and business rules can't block the merge. Any source
        # record that would duplicate one the target already owns (per a uniqueness validator OR a unique index)
        # is deleted instead of moved, so the merge never creates a duplicate or trips a unique constraint.
        klasses.each do |klass|
          source_foreign_keys(klass).each do |foreign_key, foreign_type|
            source_records = records_for(klass, foreign_key, foreign_type, source)
            next unless source_records.exists?

            attributes = { foreign_key => target.id }
            attributes[foreign_type] = target.class.name if foreign_type

            # Addresses are kept as a whole set, not merged record by record: if the target already has any
            # addresses, keep the target's and drop the source's; only copy the source's over when the target
            # has none.
            if klass.name == 'Effective::Address'
              records_for(klass, foreign_key, foreign_type, target).exists? ? source_records.delete_all : source_records.update_all(attributes)
              next
            end

            duplicate_ids = duplicate_record_ids(klass, foreign_key, foreign_type)
            source_records.where(id: duplicate_ids).delete_all if duplicate_ids.present?
            source_records.where.not(id: duplicate_ids).update_all(attributes)
          end
        end

        # Prove the merge is complete before we destroy the source: nothing may still reference it.
        assert_no_references_to_source!(klasses)

        # Everything the source owned now points at the target; whatever is left dies with the source.
        # Reload first so dependent: callbacks only fire for what STILL points at the source (update_all
        # bypasses the in-memory association cache).
        source.reload.destroy!
        target.save!(validate: validate)

        log_merged!

        success = true
      end

      success
    end

    private

    # [[foreign_key, foreign_type], ...] for every belongs_to on klass that could point at the source:
    # polymorphic, or one whose target IS the source's class (belongs_to :user, self-refs like advisor_id).
    # foreign_type is nil for non-polymorphic associations; associations missing their column are skipped.
    def source_foreign_keys(klass)
      klass.reflect_on_all_associations(:belongs_to).filter_map do |reflection|
        next unless reflection.polymorphic? || (reflection.klass == source.class rescue false)

        foreign_key = reflection.foreign_key.to_s
        next unless klass.column_names.include?(foreign_key)

        [foreign_key, (reflection.foreign_type.to_s if reflection.polymorphic?)]
      end
    end

    # The klass records owned by `owner` through foreign_key (scoped by *_type for polymorphics).
    def records_for(klass, foreign_key, foreign_type, owner)
      scope = klass.where(foreign_key => owner.id)
      foreign_type ? scope.where(foreign_type => owner.class.name) : scope
    end

    # Safety net run before we destroy the source: after the move, none of the models we moved may still point
    # at the source - otherwise destroying it would orphan or cascade-delete that record. Re-checks the same
    # klasses the move walked, so a bug there (an STI type mismatch, a row written mid-merge) fails the merge
    # loudly and rolls it back instead of losing data.
    def assert_no_references_to_source!(klasses)
      klasses.uniq(&:table_name).each do |klass|
        source_foreign_keys(klass).each do |foreign_key, foreign_type|
          next unless records_for(klass, foreign_key, foreign_type, source).exists?

          raise "Merge incomplete: #{klass.table_name}.#{foreign_key} still references #{source_type} ##{source_id}"
        end
      end
    end

    # Ids of the source's `klass` records the (authoritative) target already has an equivalent of - judged by
    # klass's uniqueness validators AND unique indexes that involve the foreign key we're repointing. These get
    # deleted instead of moved, so the merge can neither create a duplicate nor trip a unique index.
    def duplicate_record_ids(klass, foreign_key, foreign_type)
      identifying_columns = dedupe_key_columns(klass, foreign_key, foreign_type)
      return [] if identifying_columns.blank?

      source_records = records_for(klass, foreign_key, foreign_type, source)
      target_records = records_for(klass, foreign_key, foreign_type, target)

      identifying_columns.flat_map do |columns|
        if columns.empty?
          # One-per-owner (e.g. a membership, unique on the owner alone): if the target already owns one,
          # every source record is a duplicate and is dropped rather than moved into the unique constraint.
          target_records.exists? ? source_records.pluck(:id) : []
        else
          existing = target_records.pluck(*columns).map { |row| Array(row) }.to_set
          source_records.pluck(:id, *columns).filter_map { |id, *values| id if existing.include?(values) }
        end
      end.uniq
    end

    # The column sets that - together with the foreign key - make a record unique for its owner, drawn from
    # both uniqueness validators and unique indexes. The foreign key (and its *_type) is dropped from each set
    # since every moved record shares the target's value for those; an empty set means the record is unique on
    # the owner alone (one-per-owner). Partial indexes are skipped - their WHERE can't be judged from columns.
    def dedupe_key_columns(klass, foreign_key, foreign_type)
      removable = [foreign_key, foreign_type].compact

      from_validators = klass.validators.select { |validator| validator.kind == :uniqueness }.filter_map do |validator|
        columns = (Array(validator.attributes) + Array(validator.options[:scope])).map(&:to_s)
        (columns - removable) if columns.include?(foreign_key)
      end

      from_indexes =
        begin
          klass.connection.indexes(klass.table_name).filter_map do |index|
            next unless index.unique && index.where.blank?
            columns = Array(index.columns).map(&:to_s)
            (columns - removable) if columns.include?(foreign_key)
          end
        rescue StandardError
          []
        end

      (from_validators + from_indexes).uniq
    end

    def log_merged!
      return unless defined?(EffectiveLogger)

      EffectiveLogger.success(
        "Merged #{source} into #{target}",
        user: current_user,
        associated: target,
        source_id: source_id,
        target_id: target_id,
        source_email: source.try(:email),
        source_name: source.to_s
      )
    end
  end
end
