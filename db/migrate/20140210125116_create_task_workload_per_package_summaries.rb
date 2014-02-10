class CreateTaskWorkloadPerPackageSummaries < ActiveRecord::Migration
  def self.up
    create_table :task_workload_per_package_summaries do |t|
      t.integer :task_workload_summary_id
      t.integer :package_id
      t.text :workload_per_status_in_minutes

      t.timestamps
    end
  end

  def self.down
    drop_table :task_workload_per_package_summaries
  end
end
