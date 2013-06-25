class AddBzStatusToBzBugs < ActiveRecord::Migration
  def self.up
    add_column :bz_bugs, :bz_status, :string
  end

  def self.down
    remove_column :bz_bugs, :bz_status
  end
end
