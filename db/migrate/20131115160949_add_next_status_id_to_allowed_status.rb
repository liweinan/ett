class AddNextStatusIdToAllowedStatus < ActiveRecord::Migration
  def self.up
    add_column :allowed_statuses, :next_status_id, :integer
  end

  def self.down
    remove_column :allowed_statuses, :next_status_id
  end
end
