class AddCoordinatorIdToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :coordinator_id, :integer
  end

  def self.down
    remove_column :tasks, :coordinator_id
  end
end
