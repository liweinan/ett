class AddBrewTagIdToMarks < ActiveRecord::Migration
  def self.up
    add_column :marks, :brew_tag_id, :integer
  end

  def self.down
    remove_column :marks, :brew_tag_id
  end
end
