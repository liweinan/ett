class AddQueueToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :queue, :string
  end

  def self.down
    remove_column :packages, :queue
  end
end
