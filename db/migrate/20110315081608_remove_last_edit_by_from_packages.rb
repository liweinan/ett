class RemoveLastEditByFromPackages < ActiveRecord::Migration
  def self.up
    remove_column :packages, :last_edit_by
  end

  def self.down
    add_column :packages, :last_edit_by, :integer
  end
end
