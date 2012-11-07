class AddEnabledToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :enabled, :string
  end

  def self.down
    remove_column :settings, :enabled
  end
end
