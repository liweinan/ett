class RenameColumnBrewTagIdToProductIdInTableComponentViews < ActiveRecord::Migration
  def self.up
      rename_column :component_views, :brew_tag_id, :product_id
  end

  def self.down
      rename_column :component_views, :product_id, :brew_tag_id
  end
end
