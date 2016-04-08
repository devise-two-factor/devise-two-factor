shared_examples 'two_factor_authenticatable_with_customize_attr_encrypted' do
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
