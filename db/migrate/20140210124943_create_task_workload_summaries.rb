class CreateTaskWorkloadSummaries < ActiveRecord::Migration
  def self.up
    create_table :task_workload_summaries do |t|
      t.integer :task_id
      t.integer :total_number_of_packages
      t.text :workload_per_status_in_minutes

      t.timestamps
    end
  end

  def self.down
    drop_table :task_workload_summaries
  end
end
