class RenameCommentToNotes < ActiveRecord::Migration
  def self.up
    rename_column :packages, :comments, :notes
  end

  def self.down
    rename_column :packages, :notes, :comments
  end
end
