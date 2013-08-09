class AddBrewToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :brew, :string
  end

  def self.down
    remove_column :packages, :brew
  end
end
