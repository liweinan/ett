class RenameColumnLabelIdToStatusIdInTableLabelStats < ActiveRecord::Migration
  def self.up
      rename_column :label_stats, :label_id, :status_id
  end

  def self.down
      rename_column :label_stats, :status_id, :label_id
  end
end
