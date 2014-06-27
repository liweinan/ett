class AddRepositoryToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :repository, :string
  end

  def self.down
    remove_column :tasks, :repository
  end
end
