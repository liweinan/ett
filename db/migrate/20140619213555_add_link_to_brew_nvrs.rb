class AddLinkToBrewNvrs < ActiveRecord::Migration
  def self.up
    add_column :brew_nvrs, :link, :string
  end

  def self.down
    remove_column :brew_nvrs, :link
  end
end
