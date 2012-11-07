class AddCreatedByToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :created_by, :integer
  end

  def self.down
    remove_column :packages, :created_by
  end
end
