class AddIsTrackTimeToLabel < ActiveRecord::Migration
  def self.up
    add_column :labels, :is_track_time, :string
  end

  def self.down
    remove_column :labels, :is_track_time
  end
end
