# == Schema Information
#
# Table name: os_advisory_tags
#
#  id                  :integer          not null, primary key
#  os_arch             :string(255)
#  advisory            :string(255)
#  candidate_tag       :string(255)
#  task_id             :integer
#  created_at          :datetime
#  updated_at          :datetime
#  priority            :string(255)
#  target_tag          :string(255)
#  build_tag           :string(255)
#  errata_prod_release :string(255)
#

class OsAdvisoryTag < ActiveRecord::Base
  validates_presence_of :os_arch
  validates_presence_of :advisory
  validates_presence_of :candidate_tag
  validates_presence_of :task_id
  belongs_to :task
  has_many :cronjob_mode_os_advisory_tags
  has_many :cronjob_modes, :through => :cronjob_mode_os_advisory_tags

  def modes_to_build
    result = []
    cronjob_modes.each {|cron| result << cron.mode}
    result
  end

  def cron_mode_activated?(mode)
    self.modes_to_build.include? mode
  end
end
