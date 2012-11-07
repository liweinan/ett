class AddProjectNameToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :project_name, :string
  end

  def self.down
    remove_column :packages, :project_name
  end
end
