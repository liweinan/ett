class AddCanChangeCodeToStatuses < ActiveRecord::Migration
  def self.up
    add_column :statuses, :can_change_code, :string
  end

  def self.down
    remove_column :statuses, :can_change_code
  end
end
