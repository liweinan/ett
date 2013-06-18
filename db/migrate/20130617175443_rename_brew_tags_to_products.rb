class RenameBrewTagsToProducts < ActiveRecord::Migration
# TODO: fix
  def self.up
      rename_table :brew_tags, :products
  end

  def self.down
      rename_table :products, :brew_tags
  end
end
