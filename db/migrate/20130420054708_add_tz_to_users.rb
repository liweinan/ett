class AddTzToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :tz_id, :integer
  end

  def self.down
    remove_column :users, :tz_id
  end
end
