class AddExternalScmToPackage < ActiveRecord::Migration
  def self.up
    add_column :packages, :external_scm, :string
  end

  def self.down
    remove_column :packages, :external_scm
  end
end
