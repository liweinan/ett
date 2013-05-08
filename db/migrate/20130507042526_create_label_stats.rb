class CreateLabelStats < ActiveRecord::Migration
  def self.up
    create_table :label_stats do |t|
      t.integer :package_stat_id
      t.integer :label_id
      t.integer :user_id
      t.integer :minutes
      t.text :time_span
      t.timestamps
    end
  end

  def self.down
    drop_table :label_stats
  end
end
