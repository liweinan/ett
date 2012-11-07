class AddNameToRelationship < ActiveRecord::Migration
  def self.up
    add_column :relationships, :name, :string
  end

  def self.down
    remove_column :relationships, :name
  end
end
