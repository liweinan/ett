class CreateStartStatusWorkflows < ActiveRecord::Migration
  def self.up
    create_table :start_status_workflows do |t|
      t.integer :workflow_id
      t.integer :status_id

      t.timestamps
    end
  end

  def self.down
    drop_table :start_status_workflows
  end
end
