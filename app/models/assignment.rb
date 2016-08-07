# == Schema Information
#
# Table name: assignments
#
#  id         :integer          not null, primary key
#  tag_id     :integer
#  package_id :integer
#  created_at :datetime
#  updated_at :datetime
#

class Assignment < ActiveRecord::Base
  belongs_to :package
  belongs_to :tag
end
