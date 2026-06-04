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

    def to_s
      'New Merge'
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

      resource = Effective::Resource.new(source)
      success = false

      EffectiveResources.transaction do
        # Merge associations
        associations = (resource.has_ones + resource.has_manys + resource.nested_resources).compact.uniq

        associations.each do |association|
          Array(source.send(association.name)).each do |obj|
            obj.assign_attributes(association.foreign_key => target.id)
            obj.save!(validate: validate)
          end
        end

        source.destroy!
        target.save!(validate: validate)

        log_merged!

        success = true
      end

      success
    end

    private

    def log_merged!
      return unless defined?(EffectiveLogger)

      EffectiveLogger.success(
        "Merged #{source} into #{target}",
        user: current_user,
        associated: target,
        source_id: source_id,
        source_type: source_type,
        target_id: target_id,
        target_type: target_type,
        source_email: source.try(:email),
        source_name: source.to_s
      )
    end
  end
end
