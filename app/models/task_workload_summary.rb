# == Schema Information
#
# Table name: task_workload_summaries
#
#  id                             :integer          not null, primary key
#  task_id                        :integer
#  total_number_of_packages       :integer
#  workload_per_status_in_minutes :text
#  created_at                     :datetime
#  updated_at                     :datetime
#

class TaskWorkloadSummary < ActiveRecord::Base
  belongs_to :task
  validates_presence_of :task_id
end
