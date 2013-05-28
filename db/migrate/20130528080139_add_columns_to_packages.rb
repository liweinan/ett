class AddColumnsToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :sourceURL, :string
    add_column :packages, :RPM, :string
    add_column :packages, :MEAD, :string
  end

  def self.down
    remove_column :packages, :MEAD
    remove_column :packages, :RPM
    remove_column :packages, :sourceURL
  end
end
