class RemoveVersionFromPackages < ActiveRecord::Migration
  def self.up
    remove_column :packages, :version
  end

  def self.down
    add_column :packages, :version, :string
  end
end
