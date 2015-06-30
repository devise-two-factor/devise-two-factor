require 'spec_helper'
require 'active_model'

class TwoFactorAuthenticatableDouble
  include ::ActiveModel::Validations::Callbacks
  extend  ::Devise::Models

  devise :two_factor_authenticatable, :otp_secret_encryption_key => 'test-key'
end

describe ::Devise::Models::TwoFactorAuthenticatable do
  context 'When included in a class' do
    subject { TwoFactorAuthenticatableDouble.new }

    it_behaves_like 'two_factor_authenticatable'
  end
end
