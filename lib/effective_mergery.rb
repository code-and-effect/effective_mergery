require 'effective_resources'
require 'effective_mergery/engine'
require 'effective_mergery/version'

module EffectiveMergery

  def self.config_keys
    [:layout]
  end

  include EffectiveGem

  # Every model that declares a belongs_to :user, belongs_to :owner, or any polymorphic belongs_to
  # (e.g. Effective::Address#addressable), scoped to the record's world: Effective:: classes always,
  # the record's own tenant namespace when running under Tenant, and otherwise (no Tenant) every class.
  def self.mergable_klasses(record)
    Rails.application.eager_load! unless Rails.application.config.eager_load

    ActiveRecord::Base.descendants.reject(&:abstract_class?).select do |klass|
      name = klass.name.to_s
      namespaced = name.start_with?('Effective::') || (defined?(Tenant) ? name.start_with?("#{record.class.name.deconstantize}::") : true)

      namespaced && klass.reflect_on_all_associations(:belongs_to).any? { |reflection| reflection.polymorphic? || [:user, :owner].include?(reflection.name) }
    end.uniq
  end
end
