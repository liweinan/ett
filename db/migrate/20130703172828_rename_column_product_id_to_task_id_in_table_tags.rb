class RenameColumnProductIdToTaskIdInTableTags < ActiveRecord::Migration
  def self.up
      rename_column :tags, :product_id, :task_id
  end

  def self.down
      rename_column :tags, :task_id, :product_id
  end
end
