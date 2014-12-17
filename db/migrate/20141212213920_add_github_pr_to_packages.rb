class AddGithubPrToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :github_pr, :integer
    add_column :packages, :github_pr_closed, :boolean
  end

  def self.down
    remove_column :packages, :github_pr_closed
    remove_column :packages, :github_pr
  end
end
