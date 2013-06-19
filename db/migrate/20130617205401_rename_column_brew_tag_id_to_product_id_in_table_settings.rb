class RenameColumnBrewTagIdToProductIdInTableSettings < ActiveRecord::Migration
  def self.up
      rename_column :settings, :brew_tag_id, :product_id
  end

  def self.down
      rename_column :settings, :product_id, :brew_tag_id
  end
end
