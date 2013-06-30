class AddLastSyncedAtToBzBugs < ActiveRecord::Migration
  def self.up
    add_column :bz_bugs, :last_synced_at, :datetime
  end

  def self.down
    remove_column :bz_bugs, :last_synced_at
  end
end
