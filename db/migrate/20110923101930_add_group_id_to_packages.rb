class AddGroupIdToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :group_id, :string
  end

  def self.down
    remove_column :packages, :group_id
  end
end
