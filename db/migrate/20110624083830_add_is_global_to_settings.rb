class AddIsGlobalToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :is_global, :string
  end

  def self.down
    remove_column :settings, :is_global
  end
end
