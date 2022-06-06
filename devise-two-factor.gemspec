$:.push File.expand_path('lib', __dir__)
require 'devise_two_factor/version'

Gem::Specification.new do |s|
  s.name        = 'devise-two-factor'
  s.version     = DeviseTwoFactor::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.licenses    = ['MIT']
  s.summary     = 'Barebones two-factor authentication with Devise'
  s.email       = 'dev@bonus.ly'
  s.homepage    = 'https://gitlab.com/bonusly/engineering/gems/devise-two-factor'
  s.description = 'Barebones two-factor authentication with Devise'
  s.authors     = ['Shane Wilton']

  s.metadata['allowed_push_host'] = 'https://rubygems.bonusly.dev/private'
  s.files         = `git ls-files`.split("\n").delete_if { |x| x.match('demo/*') }
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['lib']

  s.add_runtime_dependency 'activesupport',  '< 7.1'
  s.add_runtime_dependency 'devise',         '~> 4.0'
  s.add_runtime_dependency 'railties',       '< 7.1'
  s.add_runtime_dependency 'rotp',           '~> 6.0'

  s.add_development_dependency 'activemodel'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'bundler', '> 1.0'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'rspec', '> 3'
  s.add_development_dependency 'simplecov'
end
