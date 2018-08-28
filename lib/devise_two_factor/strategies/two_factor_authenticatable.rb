module Devise
  module Strategies
    class TwoFactorAuthenticatable < Devise::Strategies::DatabaseAuthenticatable

      def authenticate!
        resource  = password.present? && mapping.to.find_for_database_authentication(authentication_hash)
        hashed = false

        unless resource && validate(resource){ hashed = true; resource.valid_password?(password) }
          mapping.to.new.password = password if !hashed && Devise.paranoid
          return fail!(:not_found_in_database)
        end

        if resource.otp_required_for_login
          return fail(:invalid_otp) if skip?

          unless validate(resource){ valid_otp?(resource) }
            return fail!(:invalid_otp)
          end
        end

        remember_me(resource)
        resource.after_database_authentication
        success!(resource)

        mapping.to.new.password = password if !hashed && Devise.paranoid
      end

      private

      def skip?
        params[scope].key?('otp_backup')
      end

      def valid_otp?(resource)
        return false if params[scope]['otp_attempt'].nil?
        resource.validate_and_consume_otp!(params[scope]['otp_attempt'])
      end
    end
  end
end

Warden::Strategies.add(:two_factor_authenticatable, Devise::Strategies::TwoFactorAuthenticatable)
