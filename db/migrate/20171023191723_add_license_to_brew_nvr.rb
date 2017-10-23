class AddLicenseToBrewNvr < ActiveRecord::Migration
  def self.up
    add_column :brew_nvrs, :license, :string
  end

  def self.down
    remove_column :brew_nvrs, :license
  end
end
