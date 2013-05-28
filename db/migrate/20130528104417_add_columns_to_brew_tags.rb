class AddColumnsToBrewTags < ActiveRecord::Migration
  def self.up
    add_column :brew_tags, :candidate_tag, :string
    add_column :brew_tags, :target_release, :string
  end

  def self.down
    remove_column :brew_tags, :target_release
    remove_column :brew_tags, :candidate_tag
  end
end
