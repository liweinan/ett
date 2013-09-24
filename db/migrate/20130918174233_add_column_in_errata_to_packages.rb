class AddColumnInErrataToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :in_errata, :string
  end

  def self.down
    remove_column :packages, :in_errata
  end
end
