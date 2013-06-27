class RenameLabelsToStatuses < ActiveRecord::Migration
  def self.up
      rename_table :labels, :statuses
  end

  def self.down
      rename_table :statuses, :labels
  end
end
