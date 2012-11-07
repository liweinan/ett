class RemoveDeletedFromPackages < ActiveRecord::Migration
  def self.up
    remove_column :packages, :deleted
  end

  def self.down
    add_column :packages, :deleted, :string
  end
end
