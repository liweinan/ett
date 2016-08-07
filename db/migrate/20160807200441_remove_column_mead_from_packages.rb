class RemoveColumnMeadFromPackages < ActiveRecord::Migration
  def self.up
    remove_column :packages, :MEAD
  end

  def self.down
    add_column :packages, :MEAD, :string
  end
end
