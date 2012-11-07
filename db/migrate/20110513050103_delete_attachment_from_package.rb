class DeleteAttachmentFromPackage < ActiveRecord::Migration
  def self.up
    remove_column :packages, :attachment_file_name
    remove_column :packages, :attachment_content_type
    remove_column :packages, :attachment_file_size
    remove_column :packages, :attachment_updated_at
  end

  def self.down
    add_column :packages, :attachment_file_name,    :string
    add_column :packages, :attachment_content_type, :string
    add_column :packages, :attachment_file_size,    :integer
    add_column :packages, :attachment_updated_at,   :datetime
  end
end
