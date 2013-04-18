class AddPackageIdToManualLogEntries < ActiveRecord::Migration
  def self.up
    add_column :manual_log_entries, :package_id, :integer
  end

  def self.down
    remove_column :manual_log_entries, :package_id
  end
end
