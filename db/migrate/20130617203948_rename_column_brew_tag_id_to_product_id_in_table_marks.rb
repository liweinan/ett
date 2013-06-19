class RenameColumnBrewTagIdToProductIdInTableMarks < ActiveRecord::Migration
  def self.up
      rename_column :marks, :brew_tag_id, :product_id
  end

  def self.down
      rename_column :marks, :product_id, :brew_tag_id
  end
end
