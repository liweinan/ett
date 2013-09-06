class RemoveWrapperBuildFromPackages < ActiveRecord::Migration
  def self.up
    remove_column :packages, :wrapper_build
  end

  def self.down
    add_column :packages, :wrapper_build
  end
end
