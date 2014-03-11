class TaskGroup < ActiveRecord::Base
  has_many :task_group_to_tasks
  has_many :tasks, :through => :task_group_to_tasks
end
