class AddBrewTagIdToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :brew_tag_id, :integer
  end

  def self.down
    remove_column :settings, :brew_tag_id
  end
end
