class RenameMarksToTags < ActiveRecord::Migration
  def self.up
      rename_table :marks, :tags
  end

  def self.down
      rename_table :tags, :marks
  end
end
