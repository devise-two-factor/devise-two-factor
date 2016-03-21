require 'spec_helper'

class TwoFactorBackupableDouble
  extend ::ActiveModel::Callbacks
  include ::ActiveModel::Validations::Callbacks
  extend AttrEncrypted
  extend  ::Devise::Models

  define_model_callbacks :update

  devise :two_factor_authenticatable, :two_factor_backupable,
         :otp_secret_encryption_key => 'test-key'

  attr_accessor :otp_backup_codes
end

describe ::Devise::Models::TwoFactorBackupable do
  context 'When included in a class' do
    subject { TwoFactorBackupableDouble.new }

    it_behaves_like 'two_factor_backupable'
  end
end
