class AddCreatedByToPAttachment < ActiveRecord::Migration
  def self.up
    add_column :p_attachments, :created_by, :integer
  end

  def self.down
    remove_column :p_attachments, :created_by
  end
end
