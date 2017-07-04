module EffectiveMergery
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc 'Creates an EffectiveMergery initializer in your application.'

      source_root File.expand_path('../../templates', __FILE__)

      def copy_initializer
        template ('../' * 3) + 'config/effective_mergery.rb', 'config/initializers/effective_mergery.rb'
      end

    end
  end
end
