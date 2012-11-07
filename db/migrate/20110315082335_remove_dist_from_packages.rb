class RemoveDistFromPackages < ActiveRecord::Migration
  def self.up
    remove_column :packages, :dist
  end

  def self.down
    add_column :packages, :dist, :integer
  end
end
