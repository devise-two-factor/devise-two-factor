require 'spec_helper'
require 'active_model'

class TwoFactorAuthenticatableDouble
  extend ::ActiveModel::Callbacks
  include ::ActiveModel::Validations::Callbacks
  extend  ::Devise::Models

  # stub out the ::ActiveRecord::Encryption::EncryptableRecord API
  attr_accessor :otp_secret
  def self.encrypts(*attrs)
    nil
  end

  define_model_callbacks :update

  devise :two_factor_authenticatable

  attr_accessor :consumed_timestep

  def save!(_)
    # noop for testing
    true
  end
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  it 'should be inserted prior to other devise modules' do
    expect(Devise::ALL.first).to eq(:two_factor_authenticatable)
  end

  context 'When included in a class' do
    subject { TwoFactorAuthenticatableDouble.new }

    it_behaves_like 'two_factor_authenticatable'
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

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When validate_and_consume_otp! is called with explicit drift options' do
    subject { TwoFactorAuthenticatableDouble.new }
    let(:otp_secret) { subject.class.generate_otp_secret }
    let(:default_drift) { subject.class.otp_allowed_drift }

    before :each do
      travel_to(Time.now)
      subject.otp_secret = otp_secret
      subject.consumed_timestep = nil
    end

    after :each do
      travel_back
    end

    it 'validates a future OTP outside the default drift when :drift_ahead is widened' do
      otp = ROTP::TOTP.new(otp_secret).at(Time.now + default_drift * 2)
      expect(subject.validate_and_consume_otp!(otp, drift_ahead: default_drift * 2)).to be true
    end

    it 'does not validate a past OTP outside the default drift when only :drift_ahead is widened' do
      otp = ROTP::TOTP.new(otp_secret).at(Time.now - default_drift * 2)
      expect(subject.validate_and_consume_otp!(otp, drift_ahead: default_drift * 2)).to be false
    end

    it 'widens both directions when given :allowed_drift' do
      future_otp = ROTP::TOTP.new(otp_secret).at(Time.now + default_drift * 2)
      expect(subject.validate_and_consume_otp!(future_otp, allowed_drift: default_drift * 2)).to be true
    end

    it 'prefers :drift_ahead over :allowed_drift when both are given' do
      otp = ROTP::TOTP.new(otp_secret).at(Time.now + default_drift * 2)
      result = subject.validate_and_consume_otp!(
        otp, drift_ahead: default_drift, allowed_drift: default_drift * 2
      )
      expect(result).to be false
    end
  end
end
