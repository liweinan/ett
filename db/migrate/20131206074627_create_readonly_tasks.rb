class CreateReadonlyTasks < ActiveRecord::Migration
  def self.up
    create_table :readonly_tasks do |t|
      t.integer :task_id

      t.timestamps
    end
  end

  def self.down
    drop_table :readonly_tasks
  end
end
