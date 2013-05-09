class AddWeeklyWorkloadIdToManualLogEntries < ActiveRecord::Migration
  def self.up
    add_column :manual_log_entries, :weekly_workload_id, :integer
  end

  def self.down
    remove_column :manual_log_entries, :weekly_workload_id
  end
end
