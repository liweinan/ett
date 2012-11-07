class AddActionsToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :actions, :integer
  end

  def self.down
    remove_column :settings, :actions
  end
end
