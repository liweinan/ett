class AddWorkflowIdToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :workflow_id, :integer
  end

  def self.down
    remove_column :tasks, :workflow_id
  end
end
