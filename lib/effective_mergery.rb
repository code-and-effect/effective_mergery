require 'effective_resources'
require 'effective_mergery/engine'
require 'effective_mergery/version'

module EffectiveMergery

  def self.config_keys
    [:layout, :admin_simple_form_options, :class_names]
  end

  include EffectiveGem

  # Just consider the onlies right now. sorry future matt.
  def self.mergables
    Array(class_names).map { |name| name.constantize }
  end

end
