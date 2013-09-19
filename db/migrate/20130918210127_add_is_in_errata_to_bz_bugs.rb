class AddIsInErrataToBzBugs < ActiveRecord::Migration
  def self.up
    add_column :bz_bugs, :is_in_errata, :string
  end

  def self.down
    remove_column :bz_bugs, :is_in_errata
  end
end
