class RenameColumnCloseLabelIdToCloseStatusIdInTableSettings < ActiveRecord::Migration
  def self.up
      rename_column :settings, :close_label_id, :close_status_id
  end

  def self.down
      rename_column :settings, :close_status_id, :close_label_id
  end
end
