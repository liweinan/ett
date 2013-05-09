class CreateAutoSumDetails < ActiveRecord::Migration
  def self.up
    create_table :auto_sum_details do |t|
      t.integer :weekly_workload_id
      t.integer :label_id
      t.integer :minutes

      t.timestamps
    end
  end

  def self.down
    drop_table :auto_sum_details
  end
end
