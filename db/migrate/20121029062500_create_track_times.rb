class CreateTrackTimes < ActiveRecord::Migration
  def self.up
    create_table :track_times do |t|
      t.integer :label_id
      t.integer :package_id
      t.integer :time_consumed
    end
  end

  def self.down
    drop_table :track_times
  end
end
