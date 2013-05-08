class CreateWeeklyWorkloads < ActiveRecord::Migration
  def self.up
    create_table :weekly_workloads do |t|
      t.integer :brew_tag_id
      t.datetime :start_of_week
      t.datetime :end_of_week
      t.integer :package_count
      t.integer :auto_sum
      t.integer :manual_sum

      t.timestamps
    end
  end

  def self.down
    drop_table :weekly_workloads
  end
end
