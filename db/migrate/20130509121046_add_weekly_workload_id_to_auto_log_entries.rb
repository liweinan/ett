class AddWeeklyWorkloadIdToAutoLogEntries < ActiveRecord::Migration
  def self.up
    add_column :auto_log_entries, :weekly_workload_id, :integer
  end

  def self.down
    remove_column :auto_log_entries, :weekly_workload_id
  end
end
