class AddBrewTagIdToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :brew_tag_id, :integer
  end

  def self.down
    remove_column :packages, :brew_tag_id
  end
end
