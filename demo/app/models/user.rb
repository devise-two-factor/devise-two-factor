class User < ActiveRecord::Base
  devise :two_factor_authenticatable,
         otp_encrypted_attribute_options: { key: 'f1eb1826bcd03549ed66c26e8a5fa0a55e32e242bc34dc67266b70c818243297' }

  devise :registerable, :recoverable, :rememberable,
         :trackable, :validatable
end
