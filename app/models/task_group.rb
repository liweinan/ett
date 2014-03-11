class TaskGroup < ActiveRecord::Base
  has_many :task_group_to_tasks, :dependent => :destroy
  has_many :tasks, :through => :task_group_to_tasks

  def task_ids
    _task_ids = []
    self.tasks.each do |task|
      _task_ids << task.id
    end
    _task_ids
  end
end
