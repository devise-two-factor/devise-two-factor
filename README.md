# Devise-Two-Factor Authentication
By [Tinfoil Security](http://tinfoilsecurity.com/)

Devise-two-factor is a minimalist extension to Devise which offers support for two-factor authentication. It:

* Allows you to incorporate two-factor authentication into your existing models
* Is opinionated about security, so you don't have to be
* Integrates easily with two-factor applications like Google Authenticator and Authy
* Is extensible, and includes two-factor backup codes as an example of how plugins can be structured

## Getting Started
Devise-two-factor doesn't require much to get started, but there are a few prerequisites before you can start using it in your application.

First, you'll need a Rails application setup with Devise. Visit the Devise [homepage](https://github.com/plataformatec/devise) for instructions.

You can then generate the necessary migrations for a given model by simply running:

```ruby
rails generate devise-two-factor:authenticatable MODEL
```

This generator will add a few columns to the specified model:

* encrypted_otp_secret
* encrypted_otp_secret_iv
* encrypted_otp_secret_salt
* otp_required_for_login

Next, you'll need to add the necessary Devise directives to your model. This requires that you choose an encryption key to be used when storing two-factor authentication secrets in your database. We recommend that this key be stored as an environment variable, and that it not be checked into source control.

Once you've generated a key, and determined where it will be stored, add the following line to your model:

```ruby
devise :two_factor_authenticatable, :otp_secret_encryption_key => ENV[<YOUR ENVIRONMENT VARIABLE HERE>]
```

This will register the model for the TwoFactorAuthenticatable strategy, and include the TwoFactorAuthenticatable mixin in the model.

It is also recommended that, if present, you remove :database_authenticatable from the list of loaded Devise modules - loading both strategies will cause TwoFactorAuthenticatable to be run alongside DatabaseAuthenticatable, allowing users to bypass two-factor authentication.

Note: If you're running Rails 3, you'll need to add the following to your model too:

```ruby
:attr_accessible :otp_attempt
```

Finally, you simply need to register the TwoFactorAuthenticatable strategy in your Devise initializer. You should edit your warden config block in config/initializers/devise.rb to resemble the following:

```ruby
config.warden do |manager|
  manager.default_strategies(:scope => :user).unshift :two_factor_authenticatable
end
```

## Designing Your Workflow
Devise-two-factor only worries about the backend, leaving the details of the integration up to you. This means that you're responsible for building the UI that drives the gem. While there is an example Rails application included in the gem, it is importable to remember that the gem is extremely open-ended, and you should build a user-experience which fits your individual application.

There are two key workflows you'll have to think about:

1. Logging in with two-factor authentication
2. Enabling two-factor authentication for a given user

We chose to keep things as simple as possible, and our implemention can be found by registering at [Tinfoil Security](https://tinfoilsecurity.com/), and enabling two-factor authentication from the account settings page.


### Logging In
Logging in with two-factor authentication works extremely similarly to regular database authentication in Devise. The TwoFactorAuthenticatable strategy accepts three parameters:

1. email
2. password
3. otp_attempt (Their one-time password for this session)

These parameters can be submitted to the standard Devise login route, and the strategy will handle the authentication of the user for you.

### Enabling Two-Factor Authentication
Enabling two-factor authentication for a user is easy. For example, if my user model were named User, I could do the following:

```ruby
current_user.otp_required_for_login = true
current_user.otp_secret = User.generate_otp_secret
current_user.save!
```

Before you can do this however, you need to decide how you're going to transmit two-factor tokens to a user. Common strategies include sending an SMS, or using a mobile application such as Google Authenticator.

At Tinfoil Security, we opted to use the excellent [rqrcode-rails3](https://github.com/samvincent/rqrcode-rails3) gem to generate a QR-code representing the user's secret key, which can then be scanned by any mobile two-factor authentication client.

However you decide to handle enrollment, there are a few important considerations to be made:

* Whether you'll force the use of two-factor authentication, and if so, how you'll migrate existing users to system, and what your onboarding experience will look like
* If you authenticate using SMS, you'll want to verify the user's ownership of the phone, in much the same way you're probably verifying their email address
* How you'll handle device revocation in the event that a user loses access to their device, or that device is rendered temporarily unavailable (This gem includes TwoFactorBackupable as an example extension meant to solve this problem)

It sounds like a lot of work, but most of these problems have been very elegantly solved by other people. We recommend taking a look at the excellent workflows used by Heroku and Google for inspiration.

## Backup Codes
Devise-two-factor is designed with extensibility in mind. An example extension, TwoFactorBackupable, is included. This plugin allows you to add the ability to generate single-use backup codes for a user, which they may use to bypass two-factor authentication, in the event that they lose access to their device.

Again, you'll need a migration to support backup-codes. If you're using Rails 4.0, call the following generator, otherwise skip to the next section for manual setup:

```ruby
rails generate devise-two-factor:backupable MODEL
```

You'll also need to add the follwing Devise directive to your model:

```ruby
devise :two_factor_backupable
```

Finally, you'l need to enable the TwoFactorBackupable strategy in your Devise initializer:

```ruby
manager.default_strategies(:scope => :user).unshift :two_factor_backupable
```

You can then generate backup-codes for a user:

```ruby
codes = current_user.generate_otp_backup_codes!
current_user.save!
<Display codes to the user somehow>
```

The backup-codes are stored in the database as bcrypt hashes, so be sure to display them to the user at this point. If all went well, the user should be able to login using each of the generated codes in place of their two-factor token. Each code is single-use, and generating a new set of backup-codes for that user will invalidate the old ones.

You can customize the length of each code, and the number of codes generated by passing the options into :two_factor_backupable in the Devise directive:

```ruby
devise :two_factor_backupable, otp_backup_code_length: 32,
                               otp_number_of_backup_codes: 10
```

### Help! I'm not using Rails 4.0!
Don't worry! TwoFactorBackupable stores the backup-codes as an array of strings in the database. In Rails 4.0 this is supported natively, but in earlier versions you can use a gem to emulator this behaviour: we recommend [activerecord-postgres-array](https://github.com/tlconnor/activerecord-postgres-array).

You'll then simply have to create a migration to add an array named otp_backup_codes to your model. If you use the above gem, this migration might look like:

```ruby
class AddTwoFactorBackupCodesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :otp_backup_codes, :string_array
  end
end
```

Now just continue with the setup in the previous section, skipping the generator step.

## Testing
Devise-two-factor includes shared-examples for both TwoFactorAuthenticatable and TwoFactorBackupable. Adding the following two lines to the specs for your two-factor enabled models will allow you to test your models against two-factor functionality:

```ruby
it_behaves_like "two_factor_authenticatable"
it_behaves_like "two_factor_backupable"
```
