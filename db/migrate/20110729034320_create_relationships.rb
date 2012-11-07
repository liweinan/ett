class CreateRelationships < ActiveRecord::Migration
  def self.up
    create_table :relationships do |t|
      t.string :name
      t.string :is_global
      t.integer :brew_tag_id

      t.timestamps
    end
  end

  def self.down
    drop_table :relationships
  end
end
