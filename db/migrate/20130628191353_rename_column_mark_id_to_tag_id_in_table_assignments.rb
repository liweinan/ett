class RenameColumnMarkIdToTagIdInTableAssignments < ActiveRecord::Migration
  def self.up
      rename_column :assignments, :mark_id, :tag_id
  end

  def self.down
      rename_column :assignments, :tag_id, :mark_id
  end
end
