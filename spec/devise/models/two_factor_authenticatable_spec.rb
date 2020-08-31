require 'spec_helper'
require 'support/two_factor_authenticatable_doubles'

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When included in a class' do
    subject { TwoFactorAuthenticatableDouble.new }

    it_behaves_like 'two_factor_authenticatable'
  end
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When included in a class' do
    subject { TwoFactorAuthenticatableWithCustomizeAttrEncryptedDouble.new }

    it_behaves_like 'two_factor_authenticatable'

    before :each do
      subject.otp_secret = subject.class.generate_otp_secret
      subject.consumed_timestep = nil
    end

    describe 'otp_secret options' do
      it 'should be of the key' do
        expect(subject.encrypted_attributes[:otp_secret][:key]).to eq('test-key'*8)
      end

      it 'should be of the mode' do
        expect(subject.encrypted_attributes[:otp_secret][:mode]).to eq(:per_attribute_iv_and_salt)
      end

      it 'should be of the mode' do
        expect(subject.encrypted_attributes[:otp_secret][:algorithm]).to eq('aes-256-cbc')
      end
    end
  end
end
