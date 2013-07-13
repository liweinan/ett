class AddBzAssigneeToBzBugs < ActiveRecord::Migration
  def self.up
    add_column :bz_bugs, :bz_assignee, :string
  end

  def self.down
    remove_column :bz_bugs, :bz_assignee
  end
end
