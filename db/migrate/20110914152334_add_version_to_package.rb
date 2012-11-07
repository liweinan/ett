class AddVersionToPackage < ActiveRecord::Migration
  def self.up
    add_column :packages, :version, :string
  end

  def self.down
    remove_column :packages, :version
  end
end
