class AddVerToPackage < ActiveRecord::Migration
  def self.up
    add_column :packages, :ver, :string
  end

  def self.down
    remove_column :packages, :ver
  end
end
