# == Schema Information
#
# Table name: cronjob_mode_os_advisory_tags
#
#  id                 :integer          not null, primary key
#  cronjob_mode_id    :integer
#  os_advisory_tag_id :integer
#  created_at         :datetime
#  updated_at         :datetime
#

class CronjobModeOsAdvisoryTag < ActiveRecord::Base
  belongs_to :cronjob_mode
  belongs_to :os_advisory_tag
end
