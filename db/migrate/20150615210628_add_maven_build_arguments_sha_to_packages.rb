class AddMavenBuildArgumentsShaToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :sha_maven_build_arguments, :string
  end

  def self.down
    remove_column :packages, :sha_maven_build_arguments
  end
end
