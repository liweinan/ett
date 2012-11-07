class DeleteParentIdFromBrewTags < ActiveRecord::Migration
  def self.up
    remove_column :brew_tags, :parent_id
  end

  def self.down
  end
end
