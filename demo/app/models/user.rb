class User < ActiveRecord::Base
  devise :two_factor_authenticatable,
         :otp_secret_encryption_key => ENV['ENCRYPTION_KEY']  # Set a unique encryption key for your app.
                                                                        # Store your key as an ENV variable and
                                                                        # remember to add it to .gitignore 
                                                                        # if you plan to share your code publicly.

  devise :registerable,
         :recoverable, :rememberable, :trackable, :validatable
end
