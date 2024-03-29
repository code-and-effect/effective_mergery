$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'effective_mergery/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'effective_mergery'
  s.version     = EffectiveMergery::VERSION
  s.email       = ['info@codeandeffect.com']
  s.authors     = ['Code and Effect']
  s.homepage    = 'https://github.com/code-and-effect/effective_mergery'
  s.summary     = 'Deep merge any two Active Record objects.'
  s.description = 'Deep merge any two Active Record objects.'
  s.licenses    = ['MIT']

  s.files = Dir['{app,config,lib}/**/*'] + ['MIT-LICENSE', 'README.md']

  s.add_dependency 'rails', '>= 3.2.0'
  s.add_dependency 'effective_resources'
  s.add_dependency 'coffee-rails'
  s.add_dependency 'sassc'
  s.add_dependency 'simple_form'
end
