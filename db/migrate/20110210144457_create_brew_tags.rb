class CreateBrewTags < ActiveRecord::Migration
  def self.up
    create_table :brew_tags do |t|
      t.string :name
      t.integer :parent_id

      t.timestamps
    end
  end

  def self.down
    drop_table :brew_tags
  end
end
