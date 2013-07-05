class AddGitUrlToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :git_url, :string
  end

  def self.down
    remove_column :packages, :git_url
  end
end
