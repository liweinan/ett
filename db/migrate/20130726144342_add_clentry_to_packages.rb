class AddClentryToPackages < ActiveRecord::Migration
  def self.up
      add_column :packages, :clentry, :string
  end

  def self.down
      remove_column :packages, :clentry
  end
end
