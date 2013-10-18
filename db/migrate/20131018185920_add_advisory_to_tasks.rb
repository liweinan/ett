class AddAdvisoryToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :advisory, :string
  end

  def self.down
    remove_column :tasks, :advisory
  end
end
