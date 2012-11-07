class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.integer :mark_id
      t.integer :package_id

      t.timestamps
    end
  end

  def self.down
    drop_table :assignments
  end
end
