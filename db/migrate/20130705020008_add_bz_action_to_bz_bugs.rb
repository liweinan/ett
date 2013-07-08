class AddBzActionToBzBugs < ActiveRecord::Migration
  def self.up
    add_column :bz_bugs, :bz_action, :string
  end

  def self.down
    remove_column :bz_bugs, :bz_action
  end
end
