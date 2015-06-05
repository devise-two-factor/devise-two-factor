shared_examples 'two_factor_authenticatable' do
  before :each do
    subject.otp_secret = subject.class.generate_otp_secret
  end

  describe 'required_fields' do
    it 'should have the attr_encrypted fields for otp_secret' do
      Devise::Models::TwoFactorAuthenticatable.required_fields(subject.class).should =~ ([:encrypted_otp_secret, :encrypted_otp_secret_iv, :encrypted_otp_secret_salt])
    end
  end

  describe '#otp_secret' do
    it 'should be of the configured length' do
      subject.otp_secret.length.should eq(subject.class.otp_secret_length)
    end

    it 'stores the encrypted otp_secret' do
      subject.encrypted_otp_secret.should_not be_nil
    end

    it 'stores an iv for otp_secret' do
      subject.encrypted_otp_secret_iv.should_not be_nil
    end

    it 'stores a salt for otp_secret' do
      subject.encrypted_otp_secret_salt.should_not be_nil
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
      subject.valid_otp?(otp).should be true
    end

    it 'validates an OTP within the allowed drift' do
      otp = ROTP::TOTP.new(otp_secret).at(Time.now + subject.class.otp_allowed_drift, true)
      subject.valid_otp?(otp).should be true
    end

    it 'does not validate an OTP above the allowed drift' do
      otp = ROTP::TOTP.new(otp_secret).at(Time.now + subject.class.otp_allowed_drift * 2, true)
      subject.valid_otp?(otp).should be false
    end

    it 'does not validate an OTP below the allowed drift' do
      otp = ROTP::TOTP.new(otp_secret).at(Time.now - subject.class.otp_allowed_drift * 2, true)
      subject.valid_otp?(otp).should be false
    end
  end

  describe '#otp_provisioning_uri' do
    let(:otp_secret_length) { subject.class.otp_secret_length }
    let(:account)           { Faker::Internet.email }
    let(:issuer)            { "Tinfoil" }

    it "should return uri with specified account" do
      subject.otp_provisioning_uri(account).should match(%r{otpauth://totp/#{account}\?secret=\w{#{otp_secret_length}}})
    end

    it 'should return uri with issuer option' do
      subject.otp_provisioning_uri(account, issuer: issuer).should match(%r{otpauth://totp/#{account}\?secret=\w{#{otp_secret_length}}&issuer=#{issuer}$})
    end
  end
end
