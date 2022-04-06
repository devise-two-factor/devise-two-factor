module Devise
  module Strategies
    class TwoFactorAuthenticatable < Devise::Strategies::DatabaseAuthenticatable

      def authenticate!
        resource = find_resource_from_mapping_and_auth_hash
        # We authenticate in two cases:
        # 1. The password and the OTP are correct
        # 2. The password is correct, and OTP is not required for login
        # We check the OTP, then defer to DatabaseAuthenticatable
        if validate(resource) { validate_otp(resource) }
          super
        else
          fail(Devise.paranoid ? :invalid : :not_found_in_database)
        end

        # We want to cascade to the next strategy if this one fails,
        # but database authenticatable automatically halts on a bad password
        @halted = false if @result == :failure
      end

      def validate_otp(resource)
        return true unless resource.otp_required_for_login
        return if params[scope]['otp_attempt'].nil?
        resource.validate_and_consume_otp!(params[scope]['otp_attempt'])
      end

      def find_resource_from_mapping_and_auth_hash
        mapping.to.find_for_database_authentication(authentication_hash)
      end
    end
  end
end

Warden::Strategies.add(:two_factor_authenticatable, Devise::Strategies::TwoFactorAuthenticatable)
