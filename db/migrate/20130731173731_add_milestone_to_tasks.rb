class AddMilestoneToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :milestone, :string
  end

  def self.down
    remove_column :tasks, :milestone
  end
end
