class CreateBrewNvrs < ActiveRecord::Migration
  def self.up
    create_table :brew_nvrs do |t|
      t.integer :package_id
      t.string :nvr
      t.string :distro

      t.timestamps
    end
  end

  def self.down
    drop_table :brew_nvrs
  end
end
