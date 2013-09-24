class AddRpmdiffStatusToPackage < ActiveRecord::Migration
  def self.up
    add_column :packages, :rpmdiff_status, :string
  end

  def self.down
    remove_column :packages, :rpmdiff_status
  end
end
