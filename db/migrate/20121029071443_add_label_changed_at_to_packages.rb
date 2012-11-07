class AddLabelChangedAtToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :label_changed_at, :timestamp
  end

  def self.down
    remove_column :packages, :label_changed_at
  end
end
