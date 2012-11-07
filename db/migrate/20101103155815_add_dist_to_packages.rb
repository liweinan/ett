class AddDistToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :dist, :string
  end

  def self.down
    remove_column :packages, :dist
  end
end
