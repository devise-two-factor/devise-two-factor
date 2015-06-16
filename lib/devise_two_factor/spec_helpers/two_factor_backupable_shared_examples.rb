shared_examples 'two_factor_backupable' do
  describe 'required_fields' do
    it 'has the attr_encrypted fields for otp_backup_codes' do
      Devise::Models::TwoFactorBackupable.required_fields(subject.class).should =~ [:otp_backup_codes]
    end
  end

  describe '#generate_otp_backup_codes!' do
    context 'with no existing recovery codes' do
      before do
        @plaintext_codes = subject.generate_otp_backup_codes!
      end

      it 'generates the correct number of new recovery codes' do
        subject.otp_backup_codes.length.should
          eq(subject.class.otp_number_of_backup_codes)
      end

      it 'generates recovery codes of the correct length' do
        @plaintext_codes.each do |code|
          code.length.should eq(subject.class.otp_backup_code_length)
        end
      end

      it 'generates distinct recovery codes' do
        @plaintext_codes.uniq.should =~ @plaintext_codes
      end

      it 'stores the codes as BCrypt hashes' do
        subject.otp_backup_codes.each do |code|
          # $algorithm$cost$(22 character salt + 31 character hash)
          code.should =~ /\A\$[0-9a-z]{2}\$[0-9]{2}\$[A-Za-z0-9\.\/]{53}\z/
        end
      end
    end

    context 'with existing recovery codes' do
      let(:old_codes)        { Faker::Lorem.words }
      let(:old_codes_hashed) { old_codes.map { |x| Devise::Encryptor.digest(subject.class, x) } }

      before do
        subject.otp_backup_codes = old_codes_hashed
        @plaintext_codes = subject.generate_otp_backup_codes!
      end

      it 'invalidates the existing recovery codes' do
        (subject.otp_backup_codes & old_codes_hashed).should =~ []
      end
    end
  end

  describe '#invalidate_otp_backup_code!' do
    before do
      @plaintext_codes = subject.generate_otp_backup_codes!
    end

    context 'given an invalid recovery code' do
      it 'returns false' do
        subject.invalidate_otp_backup_code!('password').should be false
      end
    end

    context 'given a valid recovery code' do
      it 'returns true' do
        @plaintext_codes.each do |code|
          subject.invalidate_otp_backup_code!(code).should be true
        end
      end

      it 'invalidates that recovery code' do
        code = @plaintext_codes.sample

        subject.invalidate_otp_backup_code!(code)
        subject.invalidate_otp_backup_code!(code).should be false
      end

      it 'does not invalidate the other recovery codes' do
        code = @plaintext_codes.sample
        subject.invalidate_otp_backup_code!(code)

        @plaintext_codes.delete(code)

        @plaintext_codes.each do |code|
          subject.invalidate_otp_backup_code!(code).should be true
        end
      end
    end
  end
end
