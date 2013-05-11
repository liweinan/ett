class CreatePackageStats < ActiveRecord::Migration
  def self.up
    create_table :package_stats do |t|
      t.integer :weekly_workload_id
      t.integer :package_id
      t.integer :user_id
      t.integer :minutes

      t.timestamps
    end
  end

  def self.down
    drop_table :package_stats
  end
end
