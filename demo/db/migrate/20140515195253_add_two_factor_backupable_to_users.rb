class AddTwoFactorBackupableToUsers < ActiveRecord::Migration
  def change
    add_column :users, :otp_backup_codes, :string, array: true
  end
end
