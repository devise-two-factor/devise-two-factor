require 'active_model'

class TwoFactorAuthenticatableDouble
  extend ::ActiveModel::Callbacks
  include ::ActiveModel::Validations::Callbacks
  extend  ::Devise::Models

  define_model_callbacks :update

  devise :two_factor_authenticatable, :otp_secret_encryption_key => 'test-key'*4

  attr_accessor :consumed_timestep

  def save(validate)
    # noop for testing
    true
  end
end

class TwoFactorAuthenticatableWithCustomizeAttrEncryptedDouble
  extend ::ActiveModel::Callbacks
  include ::ActiveModel::Validations::Callbacks

  # like https://github.com/tinfoil/devise-two-factor/blob/cf73e52043fbe45b74d68d02bc859522ad22fe73/UPGRADING.md#guide-to-upgrading-from-2x-to-3x
  extend ::AttrEncrypted
  attr_encrypted :otp_secret,
                  :key       => 'test-key'*8,
                  :mode      => :per_attribute_iv_and_salt,
                  :algorithm => 'aes-256-cbc'

  extend  ::Devise::Models

  define_model_callbacks :update

  devise :two_factor_authenticatable, :otp_secret_encryption_key => 'test-key'*4

  attr_accessor :consumed_timestep

  def save(validate)
    # noop for testing
    true
  end
end
