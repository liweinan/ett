class AddComponentViews < ActiveRecord::Migration
  def self.up
    create_table :component_views do |t|
      t.integer :component_id
      t.integer :package_id
    end
  end

  def self.down
    drop_table :component_views
  end
end
