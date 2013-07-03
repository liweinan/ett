class RenameColumnProductIdToTaskIdInTableComponentViews < ActiveRecord::Migration
  def self.up
      rename_column :component_views, :product_id, :task_id
  end

  def self.down
      rename_column :component_views, :task_id, :product_id
  end
end
