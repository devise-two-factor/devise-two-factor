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
