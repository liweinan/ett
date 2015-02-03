class AddPreviousVersionTagToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :previous_version_tag, :string
  end

  def self.down
    remove_column :tasks, :previous_version_tag
  end
end
