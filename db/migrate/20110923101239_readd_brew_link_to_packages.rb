class ReaddBrewLinkToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :brew_link, :string
  end

  def self.down
    remove_column :packages, :brew_link
  end

end
