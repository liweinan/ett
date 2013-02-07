class AddMeadToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :mead, :string
  end

  def self.down
    remove_column :packages, :mead
  end
end
