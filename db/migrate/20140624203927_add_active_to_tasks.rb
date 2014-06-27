class AddActiveToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :active, :string
  end

  def self.down
    remove_column :tasks, :active
  end
end
