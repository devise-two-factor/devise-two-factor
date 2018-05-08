module Devise
  module Strategies
    class TwoFactorBackupable < Devise::Strategies::DatabaseAuthenticatable

      def validate(resource)
        if params[scope]['otp_attempt'] && resembles_backup_code?(params[scope]['otp_attempt'])
          super(resource) { yield }
        end
      end

      def authenticate!
        resource = mapping.to.find_for_database_authentication(authentication_hash)

        if validate(resource) { resource.invalidate_otp_backup_code!(params[scope]['otp_attempt']) }
          # Devise fails to authenticate invalidated resources, but if we've
          # gotten here, the object changed (Since we deleted a recovery code)
          resource.save!
          super
        end

        fail(:not_found_in_database) unless resource

        # We want to cascade to the next strategy if this one fails,
        # but database authenticatable automatically halts on a bad password
        @halted = false if @result == :failure
      end

      private

      def resembles_backup_code?(otp_attempt)
        otp_attempt.length > 6
      end

    end
  end
end

Warden::Strategies.add(:two_factor_backupable, Devise::Strategies::TwoFactorBackupable)
