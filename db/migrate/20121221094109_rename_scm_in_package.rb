class RenameScmInPackage < ActiveRecord::Migration
  def self.up
    rename_column :packages, :scm, :internal_scm
  end

  def self.down
    rename_column :packages, :internal_scm, :scm
  end
end
