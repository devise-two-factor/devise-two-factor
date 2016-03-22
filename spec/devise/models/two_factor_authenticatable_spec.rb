require 'spec_helper'
require 'active_model'

class TwoFactorAuthenticatableDouble
  extend ::ActiveModel::Callbacks
  include ::ActiveModel::Validations::Callbacks
  extend  ::Devise::Models

  define_model_callbacks :update

  devise :two_factor_authenticatable, :otp_secret_encryption_key => 'test-key'

  attr_accessor :consumed_timestep

  def save(validate)
    # noop for testing
    true
  end
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When included in a class' do
    subject { TwoFactorAuthenticatableDouble.new }

    it_behaves_like 'two_factor_authenticatable'
  end
end
