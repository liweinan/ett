class AddUpdatedByToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :updated_by, :integer
  end

  def self.down
    remove_column :packages, :updated_by
  end
end
