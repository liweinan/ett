class AddBrewTagIdToComponentViews < ActiveRecord::Migration
  def self.up
    add_column :component_views, :brew_tag_id, :integer
  end

  def self.down
    remove_column :component_views, :brew_tag_id
  end
end
