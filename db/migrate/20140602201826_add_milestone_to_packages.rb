class AddMilestoneToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :milestone, :string
  end

  def self.down
    remove_column :packages, :milestone
  end
end
