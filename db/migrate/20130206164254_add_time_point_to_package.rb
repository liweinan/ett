class AddTimePointToPackage < ActiveRecord::Migration
  def self.up
    add_column :packages, :time_point, :integer
  end

  def self.down
    remove_column :packages, :time_point
  end
end
