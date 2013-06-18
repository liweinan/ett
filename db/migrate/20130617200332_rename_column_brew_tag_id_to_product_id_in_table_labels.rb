class RenameColumnBrewTagIdToProductIdInTableLabels < ActiveRecord::Migration
  def self.up
      rename_column :labels, :brew_tag_id, :product_id
  end

  def self.down
      rename_column :labels, :product_id, :brew_tag_id
  end
end
