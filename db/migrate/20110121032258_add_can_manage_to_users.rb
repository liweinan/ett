class AddCanManageToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :can_manage, :string
  end

  def self.down
    remove_column :users, :can_manage
  end
end
