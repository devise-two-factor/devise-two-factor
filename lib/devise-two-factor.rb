require 'attr_encrypted'
require 'devise'
require 'active_support/concern'
require 'rotp'

module Devise
  mattr_accessor :otp_secret_length
  @@otp_secret_length = 128

  mattr_accessor :otp_allowed_drift
  @@otp_allowed_drift = 30

  mattr_accessor :otp_secret_encryption_key
  @@otp_secret_encryption_key = nil

  mattr_accessor :otp_backup_code_length
  @@otp_backup_code_length = 16

  mattr_accessor :otp_number_of_backup_codes
  @@otp_number_of_backup_codes = 5
end

require 'devise/models/two_factor_authenticatable'
require 'devise/models/two_factor_backupable'
