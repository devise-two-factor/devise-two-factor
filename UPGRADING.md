# Upgrading from 4.x to 5.x

## Background

### Database columns in version 4.x and older

Versions 4.x and older stored the OTP secret in an attribute called `encrypted_otp_secret` using the [attr_encrypted](https://github.com/attr-encrypted/attr_encrypted) gem. This gem is currently unmaintained which is part of the motivation for moving to Rails encrypted attributes. This attribute was backed by three database columns:

```
encrypted_otp_secret
encrypted_otp_secret_iv
encrypted_otp_secret_salt
```

Two other columns were also created:

```
consumed_timestep
otp_required_for_login
```

A fresh install of 4.x would create all five of the database columns above.

### Database columns in version 5.x and later

Versions 5+ of this gem uses a single [Rails 7+ encrypted attribute](https://edgeguides.rubyonrails.org/active_record_encryption.html) named `otp_secret`to store the OTP secret in the database table (usually `users` but will be whatever model you picked).

A fresh install of 5+ will add the following columns to your `users` table:

```bash
otp_secret # this replaces encrypted_otp_secret, encrypted_otp_secret_iv, encrypted_otp_secret_salt
consumed_timestep
otp_required_for_login
```

### Upgrading from 4.x to 5.x


We have attempted to make the upgrade as painless as possible but unfortunately because of the secret storage change, it cannot be as simple as `bundle update devise-two-factor` :heart:

#### Assumptions

This guide assumes you are upgrading an existing Rails 6 app (with `devise` and `devise-two-factor`) to Rails 7.

This gem must be upgraded **as part of a Rails 7 upgrade**. See [the official Rails upgrading guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html) for an overview of upgrading Rails.

#### Phase 1: Upgrading devise-two-factor as part of Rails 7 upgrade

1. Update the version constraint for Rails in your `Gemfile` to your desired version e.g. `gem "rails", "~> 7.0.3"`
1. Run `bundle install` and resolve any issues with dependencies.
1. Update the version constraint for `devise-two-factor in your `Gemfile` to the the latest version (must be at least 5.x e.g. `~> 5.0`
1. Run `./bin/rails app:update as per the [Rails upgrade guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html) and tweak the output as required for your app.
1. Run `./bin/rails db:migrate` to update your DB based on the changes made by `app:update`
1. Add a new `otp_secret` attribute to your user model
    ```bash
    # TODO: replace 'User' in the migration name with the name of your user model
    ./bin/rails g migration AddOtpSecretToUser otp_secret:string
    ./bin/rails db:migrate
    ```
1. Set up [Rails encrypted secrets](https://edgeguides.rubyonrails.org/active_record_encryption.html)
    ```bash
    ./bin/rails db:encryption:init
    # capture the output and put in encrypted credentials via
    ./bin/rails credentials:edit
    ```
1. Complete your Rails 7 upgrade (making whatever other changes are required)

You can now deploy your upgraded application and devise-two-factor should work as before.

This gem will fall back to **reading** the OTP secret from the legacy columns if it cannot find one in the new `otp_secret` column. When you **write** a new OTP secret it will always be written to the new `otp_secret column.

#### Phase 2: Clean up

This "clean up" phase can happen at the same time as your initial deployment but teams managing existing apps will likely want to do clean-up as separate, later deployments.

1. Create a rake task to copy the OTP secret for each user from the legacy column to the new `otp_secret` column. This prepares the way for us to remove the legacy columns in a later step.
    ```ruby
    # lib/tasks/devise_two_factor_migration.rake

    # Use this as a starting point for your task to migrate your user's OTP secrets.
    namespace :devise_two_factor do
      desc "Copy devise_two_factor OTP secret from old format to new format"
      task copy_otp_secret_to_rails7_encrypted_attr: [:environment] do
        # TODO: change User to your user model
        User.find_each do |user| # find_each finds in batches of 1,000 by default
          otp_secret = user.otp_secret # read from otp_secret column, fall back to legacy columns if new column is empty
          puts "Processing #{user.email}"
          user.update!(otp_secret: otp_secret)
        end
      end
    end
    ```
1. Remove the now unused legacy columns from the database. This assumes you have run a rake task as in the previous step to migrate all the legacy stored secrets to the new storage.
    ```bash
    # TODO: replace 'Users' in migration name with the name of your user model
    ./bin/rails g migration RemoveLegacyDeviseTwoFactorSecretsFromUsers
    ```
    which generates
    ```ruby
    class RemoveLegacyDeviseTwoFactorSecretsFromUsers < ActiveRecord::Migration[7.0]
      def change
        # TODO: change :users to whatever your users table is

        # WARNING: Only run this when you are confident you have copied the OTP
        # secret for ALL users from `encrypted_otp_secret` to `otp_secret`!
        remove_column :users, :encrypted_otp_secret
        remove_column :users, :encrypted_otp_secret_iv
        remove_column :users, :encrypted_otp_secret_salt
      end
    end
  ```

# Guide to upgrading from 2.x to 3.x

Pull request #76 allows for compatibility with `attr_encrypted` 3.0, which should be used due to a security vulnerability discovered in 2.0.

Pull request #73 allows for compatibility with `attr_encrypted` 2.0. This version changes many of the defaults which must be taken into account to avoid corrupted OTP secrets on your model.

Due to new security practices in `attr_encrypted` an encryption key with insufficient length will cause an error. If you run into this, you may set `insecure_mode: true` in the `attr_encrypted` options.

You should initially add compatibility by specifying the `attr_encrypted` attribute in your model (`User` for these examples) with the old default encryption algorithm before invoking `devise :two_factor_authenticatable`:
```ruby
class User < ActiveRecord::Base
  attr_encrypted :otp_secret,
    :key       => self.otp_secret_encryption_key,
    :mode      => :per_attribute_iv_and_salt,
    :algorithm => 'aes-256-cbc'

  devise :two_factor_authenticatable,
         :otp_secret_encryption_key => ENV['DEVISE_TWO_FACTOR_ENCRYPTION_KEY']
```

# Guide to upgrading from 1.x to 2.x

Pull request #43 added a new field to protect against "shoulder-surfing" attacks. If upgrading, you'll need to add the `:consumed_timestep` column to your `Users` model.

```ruby
class AddConsumedTimestepToUsers < ActiveRecord::Migration
  def change
    add_column :users, :consumed_timestep, :integer
  end
end
```

All uses of the `valid_otp?` method should be switched to `validate_and_consume_otp!`
