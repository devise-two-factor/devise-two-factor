require 'attr_encrypted'
require 'rotp'

module Devise
  module Models
    module TwoFactorAuthenticatable
      extend ActiveSupport::Concern
      include Devise::Models::DatabaseAuthenticatable

      included do
        unless singleton_class.ancestors.include?(AttrEncrypted)
          extend AttrEncrypted
        end

        unless attr_encrypted?(:otp_secret)
          attr_encrypted :otp_secret,
            :key  => self.otp_secret_encryption_key,
            :mode => :per_attribute_iv_and_salt unless self.attr_encrypted?(:otp_secret)
        end

        attr_accessor :otp_attempt
      end

      def self.required_fields(klass)
        [:encrypted_otp_secret, :encrypted_otp_secret_iv, :encrypted_otp_secret_salt, :consumed_timestep]
      end

      # This defaults to the model's otp_secret
      # If this hasn't been generated yet, pass a secret as an option
      def validate_and_consume_otp!(code, options = {})
        otp_secret = options[:otp_secret] || self.otp_secret
        return false unless code.present? && otp_secret.present?

        totp = self.otp(otp_secret)
        return consume_otp! code, totp

        false
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

      # Consumes an OTP code and returns true if successful
      # @param [String] code the OTP code to check against
      # @return [Boolean] true if the code wasn't already used and a more recent code hasn't been used yet.
      #                   false if the code is invalid, as already been used or a more recent code has been consumed.
      def consume_otp!(code, totp = otp)
        self.consumed_timestep ||= 0 # TODO REMOVE only necessary to pass some tests

        otp_timestep = otp_timestep(code, totp)
        if consumed_timestep < otp_timestep
          self.consumed_timestep = otp_timestep
          return save(validate: false)
        end

        false
      end

      # Determines the time step in which the code is valid
      # @param [String] code the OTP code to determine the interval in which the code is valid
      # @return [Integer] the time step with the code is valid for or 0 if the code is invalid
      def otp_timestep(code, totp = otp)
        return 0 if otp_time(code) == nil
        otp_time(code, totp) / otp.interval
      end

      # Determines a time as an integer within the interval when the code is, was or will be valid
      # slightly changed code from @see totp#verify_with_drift
      # @param [String] code the OTP code the determine a time when the code is valid
      # @option [Integer] drift the number of seconds that the client and server are allowed to drift apart.
      # Or in other words, the number of seconds before and after the current time for which codes will be accepted
      # @option [Time] defaults to Time.now
      # @return [Integer] a time as integer when the OTP code was valid. (lies within the interval) or nil
      def otp_time(code, totp = otp, drift = self.class.otp_allowed_drift, time = Time.now)
        time = time.to_i
        times = (time-drift..time+drift).step(totp.interval).to_a
        times << time + drift if times.last < time + drift
        times.find { |ti| totp.verify(code, ti) }
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
