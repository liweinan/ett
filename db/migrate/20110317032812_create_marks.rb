class CreateMarks < ActiveRecord::Migration
  def self.up
    create_table :marks do |t|
      t.string :key
      t.text :value

      t.timestamps
    end
  end

  def self.down
    drop_table :marks
  end
end
