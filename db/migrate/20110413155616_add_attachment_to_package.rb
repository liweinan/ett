class AddAttachmentToPackage < ActiveRecord::Migration
  def self.up
    add_column :packages, :attachment_file_name,    :string
    add_column :packages, :attachment_content_type, :string
    add_column :packages, :attachment_file_size,    :integer
    add_column :packages, :attachment_updated_at,   :datetime    
  end

  def self.down
    remove_column :packages, :attachment_file_name,    :string
    remove_column :packages, :attachment_content_type, :string
    remove_column :packages, :attachment_file_size,    :integer
    remove_column :packages, :attachment_updated_at,   :datetime    
  end
end
