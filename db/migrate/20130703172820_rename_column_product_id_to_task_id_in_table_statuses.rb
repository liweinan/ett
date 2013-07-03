class RenameColumnProductIdToTaskIdInTableStatuses < ActiveRecord::Migration
  def self.up
      rename_column :statuses, :product_id, :task_id
  end

  def self.down
      rename_column :statuses, :task_id, :product_id
  end
end
