class AddScmToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :scm, :string
  end

  def self.down
    remove_column :packages, :scm
  end
end
