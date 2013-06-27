class RenameColumnLabelIdToStatusIdInTableTrackTimes < ActiveRecord::Migration
  def self.up
      rename_column :track_times, :label_id, :status_id
  end

  def self.down
      rename_column :track_times, :status_id, :label_id
  end
end
