class CreateBzBugs < ActiveRecord::Migration
  def self.up
    create_table :bz_bugs do |t|
      t.string :bz_id
      t.integer :package_id
      t.integer :creator_id

      t.timestamps
    end
  end

  def self.down
    drop_table :bz_bugs
  end
end
