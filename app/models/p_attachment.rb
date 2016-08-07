# == Schema Information
#
# Table name: p_attachments
#
#  id                      :integer          not null, primary key
#  attachment_file_name    :string(255)
#  attachment_content_type :string(255)
#  attachment_file_size    :integer
#  attachment_updated_at   :datetime
#  created_at              :datetime
#  updated_at              :datetime
#  package_id              :integer
#  created_by              :integer
#

class PAttachment < ActiveRecord::Base
  validates_presence_of :package_id
  validates_presence_of :created_by
  has_attached_file :attachment
  belongs_to :package
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
end
