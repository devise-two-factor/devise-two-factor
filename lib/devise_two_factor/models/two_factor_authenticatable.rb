require 'rotp'

module Devise
  module Models
    module TwoFactorAuthenticatable
      extend ActiveSupport::Concern
      include Devise::Models::DatabaseAuthenticatable

      included do
        unless %i[otp_secret otp_secret=].all? { |attr| method_defined?(attr) }
          encrypts :otp_secret
        end

        attr_accessor :otp_attempt
      end

      def otp_secret
        # return the OTP secret stored as a Rails encrypted attribute if it
        # exists. Otherwise return OTP secret stored by the `attr_encrypted` gem
        return self[:otp_secret] if self[:otp_secret]

        legacy_otp_secret
      end

      ##
      # Decrypt and return the `encrypted_otp_secret` attribute which was used in
      # prior versions of devise-two-factor
      #
      def legacy_otp_secret
        return nil unless self[:encrypted_otp_secret]
        return nil unless self.class.otp_secret_encryption_key

        hmac_iterations = 2000 # a default set by the Encryptor gem
        key = self.class.otp_secret_encryption_key
        salt = Base64.decode64(encrypted_otp_secret_salt)
        iv = Base64.decode64(encrypted_otp_secret_iv)

        raw_cipher_text = Base64.decode64(encrypted_otp_secret)
        # The last 16 bytes of the ciphertext are the authentication tag - we use
        # Galois Counter Mode which is an authenticated encryption mode
        cipher_text = raw_cipher_text[0..-17]
        auth_tag =  raw_cipher_text[-16..-1]

        # this alrorithm lifted from
        # https://github.com/attr-encrypted/encryptor/blob/master/lib/encryptor.rb#L54

        # create an OpenSSL object which will decrypt the AES cipher with 256 bit
        # keys in Galois Counter Mode (GCM). See
        # https://ruby.github.io/openssl/OpenSSL/Cipher.html
        cipher = OpenSSL::Cipher.new('aes-256-gcm')

        # tell the cipher we want to decrypt. Symmetric algorithms use a very
        # similar process for encryption and decryption, hence the same object can
        # do both.
        cipher.decrypt

        # Use a Password-Based Key Derivation Function to generate the key actually
        # used for encryptoin from the key we got as input.
        cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(key, salt, hmac_iterations, cipher.key_len)

        # set the Initialization Vector (IV)
        cipher.iv = iv

        # The tag must be set after calling Cipher#decrypt, Cipher#key= and
        # Cipher#iv=, but before calling Cipher#final. After all decryption is
        # performed, the tag is verified automatically in the call to Cipher#final.
        #
        # If the auth_tag does not verify, then #final will raise OpenSSL::Cipher::CipherError
        cipher.auth_tag = auth_tag

        # auth_data must be set after auth_tag has been set when decrypting See
        # http://ruby-doc.org/stdlib-2.0.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html#method-i-auth_data-3D
        # we are not adding any authenticated data but OpenSSL docs say this should
        # still be called.
        cipher.auth_data = ''

        # #update is (somewhat confusingly named) the method which actually
        # performs the decryption on the given chunk of data. Our OTP secret is
        # short so we only need to call it once.
        #
        # It is very important that we call #final because:
        #
        # 1. The authentication tag is checked during the call to #final
        # 2. Block based cipher modes (e.g. CBC) work on fixed size chunks. We need
        #    to call #final to get it to process the last chunk properly. The output
        #    of #final should be appended to the decrypted value. This isn't
        #    required for streaming cipher modes but including it is a best practice
        #    so that your code will continue to function correctly even if you later
        #    change to a block cipher mode.
        cipher.update(cipher_text) + cipher.final
      end

      def self.required_fields(klass)
        [:otp_secret, :consumed_timestep]
      end

      # This defaults to the model's otp_secret
      # If this hasn't been generated yet, pass a secret as an option
      def validate_and_consume_otp!(code, options = {})
        otp_secret = options[:otp_secret] || self.otp_secret
        return false unless code.present? && otp_secret.present?

        totp = otp(otp_secret)
        if totp.verify(code.gsub(/\s+/, ""), drift_behind: self.class.otp_allowed_drift, drift_ahead: self.class.otp_allowed_drift)
          return consume_otp!
        end

        false
      end

      def otp(otp_secret = self.otp_secret)
        ROTP::TOTP.new(otp_secret)
      end

      def current_otp
        otp.at(Time.now)
      end

      # ROTP's TOTP#timecode is private, so we duplicate it here
      def current_otp_timestep
         Time.now.utc.to_i / otp.interval
      end

      def otp_provisioning_uri(account, options = {})
        otp_secret = options[:otp_secret] || self.otp_secret
        ROTP::TOTP.new(otp_secret, options).provisioning_uri(account)
      end

      def clean_up_passwords
        super
        self.otp_attempt = nil
      end

    protected

      # An OTP cannot be used more than once in a given timestep
      # Storing timestep of last valid OTP is sufficient to satisfy this requirement
      def consume_otp!
        if self.consumed_timestep != current_otp_timestep
          self.consumed_timestep = current_otp_timestep
          return save(validate: false)
        end

        false
      end

      module ClassMethods
        Devise::Models.config(self, :otp_secret_length,
                                    :otp_allowed_drift,
                                    :otp_secret_encryption_key)

        def generate_otp_secret(otp_secret_length = self.otp_secret_length)
          ROTP::Base32.random_base32(otp_secret_length)
        end
      end
    end
  end
end
