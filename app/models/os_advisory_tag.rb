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
