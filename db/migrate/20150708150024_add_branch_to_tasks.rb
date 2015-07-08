class AddBranchToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :build_branch, :string
  end

  def self.down
    remove_column :tasks, :build_branch
  end
end
