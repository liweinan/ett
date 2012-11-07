class RemovePackageIdFromComponentViews < ActiveRecord::Migration
  def self.up
    remove_column :component_views, :package_id
  end

  def self.down
    add_column :component_views, :package_id, :integer
  end
end
