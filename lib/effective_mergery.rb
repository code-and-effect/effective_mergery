require 'effective_resources'
require 'effective_mergery/engine'
require 'effective_mergery/version'

module EffectiveMergery

  # The following are all valid config keys
  mattr_accessor :authorization_method
  mattr_accessor :layout
  mattr_accessor :admin_simple_form_options

  mattr_accessor :only
  mattr_accessor :except

  def self.setup
    yield self
  end

  def self.authorized?(controller, action, resource)
    if authorization_method.respond_to?(:call) || authorization_method.kind_of?(Symbol)
      raise Effective::AccessDenied.new() unless (controller || self).instance_exec(controller, action, resource, &authorization_method)
    end
    true
  end

  def self.mergables
    @mergables ||= (
      Rails.application.eager_load! unless Rails.configuration.cache_classes

      blacklist = ['Delayed::', 'Effective::', 'ActiveRecord::', 'ApplicationRecord']

      ActiveRecord::Base.descendants.map { |obj| obj.name }.tap do |names|
        names.reject! { |name| blacklist.any? { |b| name.start_with?(b) } }

        if (onlies = Array(only)).present?
          names.select! { |name| onlies.include?(name) }
        elsif (excepts = Array(except)).present?
          names.reject! { |name| excepts.include?(name) }
        end
      end.sort
    )
  end

end
