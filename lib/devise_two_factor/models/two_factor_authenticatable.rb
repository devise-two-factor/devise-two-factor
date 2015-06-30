require 'attr_encrypted'
require 'rotp'

module Devise
  module Models
    module TwoFactorAuthenticatable
      extend ActiveSupport::Concern
      include Devise::Models::DatabaseAuthenticatable

      included do
        attr_encrypted :otp_secret, :key  => self.otp_secret_encryption_key,
                                    :mode => :per_attribute_iv_and_salt unless self.attr_encrypted?(:otp_secret)

        attr_accessor :otp_attempt
      end

      def self.required_fields(klass)
        [:encrypted_otp_secret, :encrypted_otp_secret_iv, :encrypted_otp_secret_salt]
      end

      # This defaults to the model's otp_secret
      # If this hasn't been generated yet, pass a secret as an  option
      def valid_otp?(code, options = {})
        otp_secret = options[:otp_secret] || self.otp_secret
        return false unless otp_secret.present?

        totp = self.otp(otp_secret)
        totp.verify_with_drift(code, self.class.otp_allowed_drift)
      end

      def otp(otp_secret = self.otp_secret)
        ROTP::TOTP.new(otp_secret)
      end

      def current_otp
        otp.at(Time.now)
      end

      def otp_provisioning_uri(account, options = {})
        otp_secret = options[:otp_secret] || self.otp_secret
        ROTP::TOTP.new(otp_secret, options).provisioning_uri(account)
      end

      def clean_up_passwords
        self.otp_attempt = nil
      end

    protected

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
