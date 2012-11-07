class AddDeletedToPackage < ActiveRecord::Migration
  def self.up
    add_column :packages, :deleted, :string
  end

  def self.down
    remove_column :packages, :deleted
  end
end
