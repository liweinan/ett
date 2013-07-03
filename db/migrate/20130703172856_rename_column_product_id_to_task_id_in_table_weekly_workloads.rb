class RenameColumnProductIdToTaskIdInTableWeeklyWorkloads < ActiveRecord::Migration
  def self.up
      rename_column :weekly_workloads, :product_id, :task_id
  end

  def self.down
      rename_column :weekly_workloads, :task_id, :product_id
  end
end
