class AddLastEditByToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :last_edit_by, :integer
  end

  def self.down
    remove_column :packages, :last_edit_by
  end
end
