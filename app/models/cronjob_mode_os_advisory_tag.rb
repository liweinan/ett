class CronjobModeOsAdvisoryTag < ActiveRecord::Base
  belongs_to :cronjob_mode
  belongs_to :os_advisory_tag
end
