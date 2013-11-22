class AddStartStatusIdToWorkflow < ActiveRecord::Migration
  def self.up
    add_column :workflows, :start_status_id, :integer
  end

  def self.down
    remove_column :workflows, :start_status_id
  end
end
