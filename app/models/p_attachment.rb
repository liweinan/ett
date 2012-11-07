class PAttachment < ActiveRecord::Base
  validates_presence_of :package_id
  validates_presence_of :created_by
  has_attached_file :attachment
  belongs_to :package
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
end
