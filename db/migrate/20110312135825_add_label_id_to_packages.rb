class AddLabelIdToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :label_id, :integer
  end

  def self.down
    remove_column :packages, :label_id
  end
end
