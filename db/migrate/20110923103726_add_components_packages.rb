class AddComponentsPackages < ActiveRecord::Migration
def self.up
    create_table :components_packages do |t|
      t.integer :component_id
      t.integer :package_id
    end
  end

  def self.down
    drop_table :components_packages
  end
end
