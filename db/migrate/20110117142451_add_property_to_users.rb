class AddPropertyToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :prop, :integer
  end

  def self.down
    remove_column :users, :prop
  end
end
