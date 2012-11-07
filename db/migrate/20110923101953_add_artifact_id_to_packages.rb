class AddArtifactIdToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :artifact_id, :string
  end

  def self.down
    remove_column :packages, :artifact_id
  end
end
