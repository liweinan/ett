# == Schema Information
#
# Table name: cronjob_modes
#
#  id          :integer          not null, primary key
#  mode        :string(255)
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class CronjobMode < ActiveRecord::Base
  has_many :cronjob_mode_os_advisory_tags
  has_many :os_advisory_tags, :through => :cronjob_mode_os_advisory_tags
end
