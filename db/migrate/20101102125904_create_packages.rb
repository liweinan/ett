class CreatePackages < ActiveRecord::Migration
  def self.up
    create_table :packages do |t|
      t.string :name
      t.string :build
      t.text :comments
      t.string :state
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :packages
  end
end
