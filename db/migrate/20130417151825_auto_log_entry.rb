class AutoLogEntry < ActiveRecord::Migration
  def self.up
    create_table :auto_log_entries do |t|
      t.integer :who_id
      t.integer :label_id
      t.datetime :from
      t.datetime :to
    end

  end

  def self.down
    drop_table :auto_log_entries
  end
end
