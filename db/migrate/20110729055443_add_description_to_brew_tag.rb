class AddDescriptionToBrewTag < ActiveRecord::Migration
  def self.up
    add_column :brew_tags, :description, :text
  end

  def self.down
    remove_column :brew_tags, :description
  end
end
