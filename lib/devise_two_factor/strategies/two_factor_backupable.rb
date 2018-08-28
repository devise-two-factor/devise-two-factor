module Devise
  module Strategies
    class TwoFactorBackupable < Devise::Strategies::TwoFactorAuthenticatable

      private

      def skip?
        params[scope].key?('otp_attempt')
      end

      def valid_otp_backup?(resource)
        return false if params[scope]['otp_backup'].nil?
        resource.invalidate_otp_backup_code!(params[scope]['otp_backup']) && resource.save
      end

      alias_method :valid_otp?, :valid_otp_backup?
    end
  end
end

Warden::Strategies.add(:two_factor_backupable, Devise::Strategies::TwoFactorBackupable)
