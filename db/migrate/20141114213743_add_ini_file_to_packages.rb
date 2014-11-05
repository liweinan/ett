class AddIniFileToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :ini_file, :binary
  end

  def self.down
    remove_column :packages, :ini_file
  end
end
