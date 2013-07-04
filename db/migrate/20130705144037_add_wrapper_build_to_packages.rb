class AddWrapperBuildToPackages < ActiveRecord::Migration
  def self.up
      add_column :packages, :wrapper_build, :string
  end

  def self.down
      remove_column :packages, :wrapper_build
  end
end
