class CreatePackageRelationships < ActiveRecord::Migration
  def self.up
    create_table :package_relationships do |t|
      t.integer :from_package_id
      t.integer :to_package_id
      t.integer :relationship_id

      t.timestamps
    end
  end

  def self.down
    drop_table :package_relationships
  end
end
