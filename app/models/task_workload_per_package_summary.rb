# == Schema Information
#
# Table name: task_workload_per_package_summaries
#
#  id                             :integer          not null, primary key
#  task_workload_summary_id       :integer
#  package_id                     :integer
#  workload_per_status_in_minutes :text
#  created_at                     :datetime
#  updated_at                     :datetime
#

class TaskWorkloadPerPackageSummary < ActiveRecord::Base
end
