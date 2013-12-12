class AddOsArchToBzBugs < ActiveRecord::Migration
  def self.up
    add_column :bz_bugs, :os_arch, :string

  end

  def self.down
    remove_column :bz_bugs, :os_arch
  end
end
