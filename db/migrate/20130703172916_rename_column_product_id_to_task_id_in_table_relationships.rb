class RenameColumnProductIdToTaskIdInTableRelationships < ActiveRecord::Migration
  def self.up
      rename_column :relationships, :product_id, :task_id
  end

  def self.down
      rename_column :relationships, :task_id, :product_id
  end
end
