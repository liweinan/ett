class AddReadOnlyToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :read_only_task, :boolean
  end

  def self.down
    remove_column :tasks, :read_only_task
  end
end
