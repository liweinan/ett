class AddSpecFileToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :spec_file, :binary
  end

  def self.down
    remove_column :packages, :spec_file
  end
end
