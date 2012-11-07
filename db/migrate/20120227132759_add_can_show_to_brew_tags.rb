class AddCanShowToBrewTags < ActiveRecord::Migration
  def self.up
    add_column :brew_tags, :can_show, :string
  end

  def self.down
    remove_column :brew_tags, :can_show
  end
end
