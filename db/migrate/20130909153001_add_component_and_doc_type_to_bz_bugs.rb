class AddComponentAndDocTypeToBzBugs < ActiveRecord::Migration
  def self.up
    add_column :bz_bugs, :component, :string
    add_column :bz_bugs, :doc_type, :string
  end

  def self.down
    remove_column :bz_bugs, :component
    remove_column :bz_bugs, :doc_type
  end
end
