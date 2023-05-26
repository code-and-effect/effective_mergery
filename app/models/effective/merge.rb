module Effective
  class Merge
    include ActiveModel::Model

    attr_accessor :type, :source, :source_id, :target, :target_id

    validate(if: -> { source_id.present? }) { @source ||= collection.find_by_id(source_id) }
    validate(if: -> { target_id.present? }) { @target ||= collection.find_by_id(target_id) }

    validates :type, presence: true
    validates :source_id, presence: true, unless: -> { source.present? }
    validates :target_id, presence: true, unless: -> { target.present? }

    validate(if: -> { source_id.present? && target_id.present? }) do
      self.errors.add(:target_id, "can't be the same as source") if source_id == target_id
    end

    validates :source, presence: { message: 'invalid source id' }, if: -> { source_id.present? }
    validates :target, presence: { message: 'invalid target id' }, if: -> { target_id.present? }

    def to_s
      return 'New Merge' unless type
      type.downcase
    end

    def save(validate: true)
      return false unless valid?
      (merge!(validate: validate) rescue false)
    end

    def save!(validate: true)
      raise 'is invalid' unless valid?
      merge!(validate: validate)
    end

    def collection
      @collection ||= (klass.respond_to?(:effective_mergery_collection) ? klass.effective_mergery_collection : klass.all)
    end

    def form_collection
      @form_collection ||= (klass.respond_to?(:effective_mergery_form_collection) ? klass.effective_mergery_form_collection : collection)
    end

    def klass
      @klass ||= type.safe_constantize
    end

    # This is called on Admin::Merges#new
    def validate_klass!
      raise "type can't be blank" unless type.present?
      raise 'type must be a mergable type' unless EffectiveMergery.mergables.map(&:name).include?(type)
      raise "invalid ActiveRecord klass" unless klass
      raise "invalid ActiveRecord collection" unless collection.kind_of?(ActiveRecord::Relation)
      true
    end

    private

    def merge!(validate: true)
      resource = Effective::Resource.new(source)
      success = false

      klass.transaction do
        # Merge associations
        (resource.has_ones + resource.has_manys + resource.nested_resources).compact.each do |association|
          next if association.options[:through].present?

          Array(source.send(association.name)).each do |obj|
            obj.assign_attributes(association.foreign_key => target.id)
            obj.save!(validate: validate)
          end
        end

        source.destroy!

        target.save!(validate: validate)
        success = true
      end

      success
    end

  end
end
