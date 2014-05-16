class User < ActiveRecord::Base
  devise :two_factor_authenticatable,
         :otp_secret_encryption_key => ENV['your_encryption_key_here']

  devise :registerable,
         :recoverable, :rememberable, :trackable, :validatable
end
