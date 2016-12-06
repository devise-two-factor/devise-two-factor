class User < ActiveRecord::Base
  devise :two_factor_authenticatable,
         # Set a unique encryption key for your app.
         # Store your key as an ENV variable and
         # remember to add it to .gitignore
         # if you plan to share your code publicly.
         otp_secret_encryption_key: ENV['ENCRYPTION_KEY']

  devise :registerable, :recoverable, :rememberable,
         :trackable, :validatable
end
