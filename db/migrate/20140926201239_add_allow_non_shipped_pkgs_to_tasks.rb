class AddAllowNonShippedPkgsToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :allow_non_shipped_pkgs, :boolean
  end

  def self.down
    remove_column :tasks, :allow_non_shipped_pkgs
  end
end
