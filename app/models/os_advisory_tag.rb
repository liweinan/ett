class OsAdvisoryTag < ActiveRecord::Base
  validates_presence_of :os_arch
  validates_presence_of :advisory
  validates_presence_of :candidate_tag
  validates_presence_of :task_id
  belongs_to :task
end
