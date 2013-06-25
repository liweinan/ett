class RenameColumnLabelIdToStatusIdInTableAutoLogEntries < ActiveRecord::Migration
  def self.up
      rename_column :auto_log_entries, :label_id, :status_id
  end

  def self.down
      rename_column :auto_log_entries, :status_id, :label_id
  end
end
