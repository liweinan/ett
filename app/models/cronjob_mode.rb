class CronjobMode < ActiveRecord::Base
  has_many :cronjob_mode_os_advisory_tags
  has_many :os_advisory_tags, :through => :cronjob_mode_os_advisory_tags
end
