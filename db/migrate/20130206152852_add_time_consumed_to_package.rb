class AddTimeConsumedToPackage < ActiveRecord::Migration
  def self.up
    add_column :packages, :time_consumed, :integer
  end

  def self.down
    remove_column :packages, :time_consumed
  end
end
