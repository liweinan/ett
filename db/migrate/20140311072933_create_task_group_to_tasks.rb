class CreateTaskGroupToTasks < ActiveRecord::Migration
  def self.up
    create_table :task_group_to_tasks do |t|
      t.integer :task_group_id
      t.integer :task_id

      t.timestamps
    end
  end

  def self.down
    drop_table :task_group_to_tasks
  end
end
