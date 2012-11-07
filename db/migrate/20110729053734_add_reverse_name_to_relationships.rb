class AddReverseNameToRelationships < ActiveRecord::Migration
  def self.up
    add_column :relationships, :reverse_name, :string
  end

  def self.down
    remove_column :relationships, :reverse_name
  end
end
