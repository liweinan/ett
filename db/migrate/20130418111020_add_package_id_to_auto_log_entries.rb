class AddPackageIdToAutoLogEntries < ActiveRecord::Migration
  def self.up
    add_column :auto_log_entries, :package_id, :integer
  end

  def self.down
    remove_column :auto_log_entries, :package_id
  end
end
