class AddLicenseToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :license, :string
  end

  def self.down
    remove_column :packages, :license
  end
end
