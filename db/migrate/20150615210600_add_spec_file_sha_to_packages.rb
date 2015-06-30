class AddSpecFileShaToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :sha_spec_file, :string
  end

  def self.down
    remove_column :packages, :sha_spec_file
  end
end
