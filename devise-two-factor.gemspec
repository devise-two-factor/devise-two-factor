$:.push File.expand_path('../lib', __FILE__)
require 'devise_two_factor/version'

Gem::Specification.new do |s|
  s.name        = 'devise-two-factor'
  s.version     = DeviseTwoFactor::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.licenses    = ['MIT']
  s.summary     = 'Barebones two-factor authentication with Devise'
  s.email       = 'engineers@tinfoilsecurity.com'
  s.homepage    = 'https://github.com/tinfoil/devise-two-factor'
  s.description = 'Barebones two-factor authentication with Devise'
  s.authors     = ['Shane Wilton']

  s.rubyforge_project = 'devise-two-factor'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['lib']

  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'activemodel'
  s.add_runtime_dependency 'attr_encrypted'
  s.add_runtime_dependency 'devise'
  s.add_runtime_dependency 'rotp'

  s.add_development_dependency 'bundler',   '> 1.0'
  s.add_development_dependency 'rspec',     '~> 2.8'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'timecop'
end
