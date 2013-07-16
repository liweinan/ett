class AddTagVersionToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :tag_version, :string
  end

  def self.down
    remove_column :tasks, :tag_version
  end
end
