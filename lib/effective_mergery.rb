require 'effective_resources'
require 'effective_mergery/engine'
require 'effective_mergery/version'

module EffectiveMergery

  def self.config_keys
    [:layout]
  end

  include EffectiveGem
end
