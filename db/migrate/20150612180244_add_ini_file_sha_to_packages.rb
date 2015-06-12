class AddIniFileShaToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :sha_ini_file, :string
  end

  def self.down
    remove_column :packages, :sha_ini_file
  end
end
