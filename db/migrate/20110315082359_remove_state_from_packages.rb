class RemoveStateFromPackages < ActiveRecord::Migration
  def self.up
    remove_column :packages, :state
  end

  def self.down
    add_column :packages, :state, :string
  end
end
