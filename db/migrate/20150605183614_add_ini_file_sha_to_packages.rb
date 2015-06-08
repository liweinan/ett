class AddIniFileShaToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :ini_file_sha, :string
  end

  def self.down
    remove_column :packages, :ini_file_sha
  end
end
