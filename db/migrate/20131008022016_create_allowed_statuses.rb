class CreateAllowedStatuses < ActiveRecord::Migration
  def self.up
    create_table :allowed_statuses do |t|
      t.integer :workflow_id
      t.integer :status_id
      t.text :next_statuses

      t.timestamps
    end
  end

  def self.down
    drop_table :allowed_statuses
  end
end
