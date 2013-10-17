class AddBrewScmUrlToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :brew_scm_url, :string
  end

  def self.down
    remove_column :packages, :brew_scm_url
  end
end
