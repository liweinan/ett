class CreateChangelogs < ActiveRecord::Migration
  def self.up
    create_table :changelogs do |t|
      t.integer :package_id
      t.integer :changed_by
      t.string :category
      t.string :references
      t.text :from_value
      t.text :to_value
      t.timestamp :changed_at
    end
  end

  def self.down
    drop_table :changelogs
  end
end
