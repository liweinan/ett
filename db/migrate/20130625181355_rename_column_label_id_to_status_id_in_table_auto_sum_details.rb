class RenameColumnLabelIdToStatusIdInTableAutoSumDetails < ActiveRecord::Migration
  def self.up
      rename_column :auto_sum_details, :label_id, :status_id
  end

  def self.down
      rename_column :auto_sum_details, :status_id, :label_id
  end
end
