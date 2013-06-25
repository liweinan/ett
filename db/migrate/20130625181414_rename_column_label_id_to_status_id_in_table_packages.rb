class RenameColumnLabelIdToStatusIdInTablePackages < ActiveRecord::Migration
  def self.up
      rename_column :packages, :label_id, :status_id
  end

  def self.down
      rename_column :packages, :status_id, :label_id
  end
end
