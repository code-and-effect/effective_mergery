module EffectiveMergery
  class Engine < ::Rails::Engine
    engine_name 'effective_mergery'

    # Set up our default configuration options.
    initializer "effective_mergery.defaults", before: :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_mergery.rb")
    end

  end
end
