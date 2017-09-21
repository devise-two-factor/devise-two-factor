class AddLastotpatToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_otp_at, :datetime
  end
end
