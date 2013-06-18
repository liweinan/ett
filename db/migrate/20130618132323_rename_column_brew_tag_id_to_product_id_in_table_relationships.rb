class RenameColumnBrewTagIdToProductIdInTableRelationships < ActiveRecord::Migration
  def self.up
      rename_column :relationships, :brew_tag_id, :product_id
  end

  def self.down
      rename_column :relationships, :product_id, :brew_tag_id
  end
end
