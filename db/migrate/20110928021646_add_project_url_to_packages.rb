class AddProjectUrlToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :project_url, :string
  end

  def self.down
    remove_column :packages, :project_url
  end
end
