class AddMavenBuildArgumentsToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :maven_build_arguments, :binary
  end

  def self.down
    remove_column :packages, :maven_build_arguments
  end
end
