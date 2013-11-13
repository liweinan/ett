class AddLatestBrewNvrToPackage < ActiveRecord::Migration
  def self.up
    add_column :packages, :latest_brew_nvr, :string
  end

  def self.down
    remove_column :packages, :latest_brew_nvr
  end
end
