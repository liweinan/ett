class AddPackageIdToPAttachment < ActiveRecord::Migration
  def self.up
    add_column :p_attachments, :package_id, :integer
  end

  def self.down
    remove_column :p_attachments, :package_id
  end
end
