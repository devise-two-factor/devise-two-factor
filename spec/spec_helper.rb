require 'rails'
require 'active_record'
require 'simplecov'

module SimpleCov::Configuration
  def clean_filters
    @filters = []
  end
end

SimpleCov.configure do
  clean_filters
  load_profile 'test_frameworks'
end

ENV["COVERAGE"] && SimpleCov.start do
  add_filter "/.rvm/"
end
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'faker'
require 'devise-two-factor'
require 'devise_two_factor/spec_helpers'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run_when_matching :focus
end

Rails.logger = ActiveRecord::Base.logger = ActiveSupport::Logger.new("debug.log", 0, 100 * 1024 * 1024)

ActiveRecord::Base.configurations = {
  devise_two_factor_unit: {
    adapter: 'sqlite3',
    database: ':memory:'
  }
}

ActiveRecord::Encryption.configure(
  primary_key: 'test master key',
  deterministic_key: 'test deterministic key',
  key_derivation_salt: 'testing key derivation salt'
)

ActiveRecord::Base.establish_connection :devise_two_factor_unit
