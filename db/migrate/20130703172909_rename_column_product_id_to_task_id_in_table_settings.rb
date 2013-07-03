class RenameColumnProductIdToTaskIdInTableSettings < ActiveRecord::Migration
  def self.up
      rename_column :settings, :product_id, :task_id
  end

  def self.down
      rename_column :settings, :task_id, :product_id
  end
end
