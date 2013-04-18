class CreateManualLogEntries < ActiveRecord::Migration
  def self.up
    create_table :manual_log_entries do |t|
      t.integer :who_id
      t.datetime :from
      t.datetime :to

      t.timestamps
    end
  end

  def self.down
    drop_table :manual_log_entries
  end
end
