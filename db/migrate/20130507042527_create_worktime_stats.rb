class CreateWorktimeStats < ActiveRecord::Migration
  def self.up
    create_table :worktime_stats do |t|
      t.integer :package_stat_id
      t.integer :user_id
      t.integer :minutes
      t.text :time_span
      t.timestamps
    end
  end

  def self.down
    drop_table :worktime_stats
  end
end
