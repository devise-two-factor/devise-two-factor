shared_examples 'two_factor_authenticatable' do
  before :each do
    subject.otp_secret = subject.class.generate_otp_secret
  end

  describe 'required_fields' do
    it 'should have the attr_encrypted fields for otp_secret' do
      expect(Devise::Models::TwoFactorAuthenticatable.required_fields(subject.class)).to contain_exactly(:encrypted_otp_secret, :encrypted_otp_secret_iv, :encrypted_otp_secret_salt)
    end
  end

  describe '#otp_secret' do
    it 'should be of the configured length' do
      expect(subject.otp_secret.length).to eq(subject.class.otp_secret_length)
    end

    it 'stores the encrypted otp_secret' do
      expect(subject.encrypted_otp_secret).to_not be_nil
    end

    it 'stores an iv for otp_secret' do
      expect(subject.encrypted_otp_secret_iv).to_not be_nil
    end

    it 'stores a salt for otp_secret' do
      expect(subject.encrypted_otp_secret_salt).to_not be_nil
    end
  end

  describe '#valid_otp?' do
    let(:otp_secret) { '2z6hxkdwi3uvrnpn' }

    before :each do
      Timecop.freeze(Time.current)
      subject.otp_secret = otp_secret
    end

    after :each do
      Timecop.return
    end

    it 'validates a precisely correct OTP' do
      otp = ROTP::TOTP.new(otp_secret).at(Time.now)
      expect(subject.valid_otp?(otp)).to be true
    end

    it 'validates an OTP within the allowed drift' do
      otp = ROTP::TOTP.new(otp_secret).at(Time.now + subject.class.otp_allowed_drift, true)
      expect(subject.valid_otp?(otp)).to be true
    end

    it 'does not validate an OTP above the allowed drift' do
      otp = ROTP::TOTP.new(otp_secret).at(Time.now + subject.class.otp_allowed_drift * 2, true)
      expect(subject.valid_otp?(otp)).to be false
    end

    it 'does not validate an OTP below the allowed drift' do
      otp = ROTP::TOTP.new(otp_secret).at(Time.now - subject.class.otp_allowed_drift * 2, true)
      expect(subject.valid_otp?(otp)).to be false
    end
  end

  describe '#otp_provisioning_uri' do
    let(:otp_secret_length) { subject.class.otp_secret_length }
    let(:account)           { Faker::Internet.email }
    let(:issuer)            { "Tinfoil" }

    it "should return uri with specified account" do
      expect(subject.otp_provisioning_uri(account)).to match(%r{otpauth://totp/#{account}\?secret=\w{#{otp_secret_length}}})
    end

    it 'should return uri with issuer option' do
      expect(subject.otp_provisioning_uri(account, issuer: issuer)).to match(%r{otpauth://totp/#{account}\?secret=\w{#{otp_secret_length}}&issuer=#{issuer}$})
    end
  end
end
