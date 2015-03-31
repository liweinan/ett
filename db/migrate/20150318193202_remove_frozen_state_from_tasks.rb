class RemoveFrozenStateFromTasks < ActiveRecord::Migration
  def self.up
    remove_column :tasks, :frozen_state
  end

  def self.down
    add_colum :tasks, :frozen_state, :string
  end
end
