class AddAllowNonExistentPkgsToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :allow_non_existent_pkgs, :boolean
  end

  def self.down
    remove_column :tasks, :allow_non_existent_pkgs
  end
end
