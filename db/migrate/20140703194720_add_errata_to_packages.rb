class AddErrataToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :errata, :string
  end

  def self.down
    remove_column :packages, :errata
  end
end
