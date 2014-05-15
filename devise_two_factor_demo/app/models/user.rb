class User < ActiveRecord::Base
  devise :two_factor_authenticatable, :two_factor_backupable,
         :registerable, :recoverable, :rememberable, :trackable, :validatable,
         :otp_secret_encryption_key => 'Thisshouldbeanenvironmentvariable'
end
