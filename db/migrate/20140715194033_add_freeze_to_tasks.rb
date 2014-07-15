class AddFreezeToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :frozen_state, :string
  end

  def self.down
    remove_column :tasks, :frozen_state
  end
end
