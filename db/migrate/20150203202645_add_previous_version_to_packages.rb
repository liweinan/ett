class AddPreviousVersionToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :previous_version, :string
  end

  def self.down
    remove_column :packages, :previous_version
  end
end
