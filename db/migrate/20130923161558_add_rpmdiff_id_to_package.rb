class AddRpmdiffIdToPackage < ActiveRecord::Migration
  def self.up
    add_column :packages, :rpmdiff_id, :string
  end

  def self.down
    remove_column :packages, :rpmdiff_id
  end
end
