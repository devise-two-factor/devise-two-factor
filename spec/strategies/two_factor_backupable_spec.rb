require 'spec_helper'
require 'active_model'

class TwoFactorBackupableDouble
  extend ::ActiveModel::Callbacks
  include ::ActiveModel::Validations::Callbacks
  extend  ::Devise::Models

  define_model_callbacks :update

  devise :two_factor_authenticatable, :two_factor_backupable,
         :otp_secret_encryption_key => 'test-key'*4

  attr_accessor :otp_backup_codes
end

describe Devise::Strategies::TwoFactorBackupable do

  let(:strategy){ Devise::Strategies::TwoFactorBackupable }
  let(:resource) { TwoFactorBackupableDouble.new }

  subject{ strategy.new(env_with_params('/', { user: { otp_attempt: '123456' } } ), 'user') }

  it 'No OTP attempt (Normal login)' do
    subject = strategy.new(env_with_params('/', { user: { otp_attempt: nil } } ), 'user')
    allow(subject).to receive_message_chain(:mapping, :to, :find_for_database_authentication) { resource }

    subject._run!
    expect(subject.result).to be_nil
  end

  it 'OTP attempt with 6 digits (Google Authenticator)' do
    allow(subject).to receive_message_chain(:mapping, :to, :find_for_database_authentication) { resource }

    subject._run!
    expect(subject.result).to be_nil
  end

  it 'OTP attempt with 7 digits (Backup code)' do
    subject = strategy.new(env_with_params('/', { user: { otp_attempt: '1234567' } } ), 'user')
    allow(resource).to receive(:invalidate_otp_backup_code!).and_return(true)
    allow(resource).to receive(:save!).and_return(true)
    allow(subject).to receive_message_chain(:mapping, :to, :find_for_database_authentication) { resource }

    subject._run!
    expect(subject.result).to eql :failure
  end

  def env_with_params(path = "/", params = {}, env = {})
    method = params.delete(:method) || "GET"
    env = { 'HTTP_VERSION' => '1.1', 'REQUEST_METHOD' => "#{method}" }.merge(env)
    Rack::MockRequest.env_for("#{path}?#{Rack::Utils.build_nested_query(params)}", env)
  end
end
