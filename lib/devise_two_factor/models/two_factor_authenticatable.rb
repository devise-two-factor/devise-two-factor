
require 'rotp'

module Devise
  module Models
    module TwoFactorAuthenticatable
      extend ActiveSupport::Concern
      include Devise::Models::DatabaseAuthenticatable

      included do
        attr_accessor :otp_attempt

        encrypts :otp_secret, **two_factor_otp_secret_encrypts_options
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

        if self.consumed_timestep
          # reconstruct the timestamp of the last consumed timestep
          after_timestamp = self.consumed_timestep * otp.interval
        end

        if totp.verify(code.gsub(/\s+/, ""), drift_behind: self.class.otp_allowed_drift, drift_ahead: self.class.otp_allowed_drift, after: after_timestamp)
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
                                    :otp_secret_encryption_key,
                                    :otp_secret_encryption_options)

        def generate_otp_secret(otp_secret_length = self.otp_secret_length)
          ROTP::Base32.random_base32(otp_secret_length)
        end

        def two_factor_otp_secret_encrypts_options
          if otp_secret_encryption_key.present?
            { key: otp_secret_encryption_key }
          else
            otp_secret_encryption_options
          end
        end
      end
    end
  end
end
