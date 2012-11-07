class RemoveBrewLinkFromPackages < ActiveRecord::Migration
  def self.up
    remove_column :packages, :brew_link
  end

  def self.down
    add_column :packages, :brew_link, :string
  end
end
