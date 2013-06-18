class RenameColumnBrewTagIdToProductIdInTablePackages < ActiveRecord::Migration
  def self.up
      rename_column :packages, :brew_tag_id, :product_id
  end

  def self.down
      rename_column :packages, :product_id, :brew_tag_id
  end
end
