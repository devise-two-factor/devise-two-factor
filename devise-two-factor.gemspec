$:.push File.expand_path("../lib", __FILE__)
require "devise_two_factor/version"

Gem::Specification.new do |s|
  s.name        = "devise-two-factor"
  s.version     = DeviseTwoFactor::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.licenses    = ["MIT"]
  s.summary     = "Barebones two-factor authentication with Devise"
  s.email       = "shane@tinfoilsecurity.com"
  s.homepage    = "https://github.com/tinfoil/devise-two-factor"
  s.description = "Barebones two-factor authentication with Devise"
  s.authors     = ['Shane Wilton']

  s.rubyforge_project = "devise-two-factor"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["lib"]
end
