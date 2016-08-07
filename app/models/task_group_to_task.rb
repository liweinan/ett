# == Schema Information
#
# Table name: task_group_to_tasks
#
#  id            :integer          not null, primary key
#  task_group_id :integer
#  task_id       :integer
#  created_at    :datetime
#  updated_at    :datetime
#

class TaskGroupToTask < ActiveRecord::Base
  belongs_to :task_group
  belongs_to :task
end
