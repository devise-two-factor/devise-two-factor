require 'spec_helper'
require 'active_model'

ActiveRecord::Base.connection.create_table :two_factor_authenticatable_doubles, force: true do |t|
  t.string :otp_secret
end

class TwoFactorAuthenticatableDouble < ActiveRecord::Base
  extend  ::Devise::Models

  define_model_callbacks :update

  devise :two_factor_authenticatable, :otp_secret_encryption_key => 'test-key' * 4

  attr_accessor :consumed_timestep

  def save(validate)
    # noop for testing
    true
  end
end

ActiveRecord::Base.connection.create_table :two_factor_authenticatable_with_custom_options_doubles, force: true do |t|
  t.string :otp_secret
end

class TwoFactorAuthenticatableWithCustomOptionsDouble < ActiveRecord::Base
  extend  ::Devise::Models

  define_model_callbacks :update

  devise :two_factor_authenticatable, :otp_secret_encryption_options => {
    key_provider: ActiveRecord::Encryption::DeterministicKeyProvider.new('test-key' * 8)
  }

  attr_accessor :consumed_timestep

  def save(validate)
    # noop for testing
    true
  end
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When included in a class' do
    subject { TwoFactorAuthenticatableDouble.new }

    it_behaves_like 'two_factor_authenticatable'
  end
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When included in a class' do
    subject { TwoFactorAuthenticatableWithCustomOptionsDouble.new }

    it_behaves_like 'two_factor_authenticatable'

    before :each do
      subject.otp_secret = subject.class.generate_otp_secret
      subject.consumed_timestep = nil
    end

    describe 'otp_secret options' do
      it 'should set the options' do
        expect(subject.class.attribute_types['otp_secret'].scheme.to_h).to match(hash_including(
          key_provider: instance_of(ActiveRecord::Encryption::DeterministicKeyProvider)
        ))
      end
    end
  end
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When clean_up_passwords is called ' do
    subject { TwoFactorAuthenticatableDouble.new }
    before :each do
      subject.otp_attempt = 'foo'
      subject.password_confirmation = 'foo'
    end
    it 'otp_attempt should be nill' do 
      subject.clean_up_passwords
      expect(subject.otp_attempt).to be_nil
    end
    it 'password_confirmation should be nill' do 
      subject.clean_up_passwords
      expect(subject.password_confirmation).to be_nil
    end
  end
end


