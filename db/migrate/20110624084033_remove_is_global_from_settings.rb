class RemoveIsGlobalFromSettings < ActiveRecord::Migration
  def self.up
    remove_column :settings, :is_global
  end

  def self.down
    add_column :settings, :is_global, :integer
  end
end
