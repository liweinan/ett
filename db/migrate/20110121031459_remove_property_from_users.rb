class RemovePropertyFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :prop
  end

  def self.down
    add_column :users, :prop, :integer
  end
end
