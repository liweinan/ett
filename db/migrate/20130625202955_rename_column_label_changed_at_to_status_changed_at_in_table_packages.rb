class RenameColumnLabelChangedAtToStatusChangedAtInTablePackages < ActiveRecord::Migration
  def self.up
      rename_column :packages, :label_changed_at, :status_changed_at
  end

  def self.down
      rename_column :packages, :status_changed_at, :label_changed_at
  end
end
