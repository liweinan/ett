class RenameColumnProductIdToTaskIdInTablePackages < ActiveRecord::Migration
  def self.up
      rename_column :packages, :product_id, :task_id
  end

  def self.down
      rename_column :packages, :task_id, :product_id
  end
end
