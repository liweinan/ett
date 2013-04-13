class AddTotalManualTrackTimeToBrewTag < ActiveRecord::Migration
  def self.up
    add_column :brew_tags, :total_manual_track_time, :integer
  end

  def self.down
    remove_column :brew_tags, :total_manual_track_time
  end
end
