class RenameColumnsOfRelationships < ActiveRecord::Migration
  def self.up
    rename_column :relationships, :name, :from_name
    rename_column :relationships, :reverse_name, :to_name
  end

  def self.down
    rename_column :relationships, :from_name, :name
    rename_column :relationships, :to_name, :reverse_name
  end
end
