class Workflow < ActiveRecord::Base
  belongs_to :start_status, :class_name => "Status", :foreign_key => "start_status_id"

  has_many :allowed_statuses
  has_many :tasks

  validates_presence_of :name
  validates_presence_of :start_status_id, :message => "is not defined."

  def update_transitions(transitions) # this method should be surrounded with a transaction
    return if transitions.blank?

    Workflow.transaction do # this nested transaction should merge with the transaction in caller
      allowed_statuses.each do |as|
        as.destroy
      end

      transitions.each do |transition|
        allowed_status = AllowedStatus.new
        tuple = Workflow.process_transition(transition)
        allowed_status.status_id = tuple[:current].to_i
        allowed_status.next_status_id = tuple[:next].to_i
        allowed_status.workflow_id = id
        allowed_status.save
      end
    end
  end

  def has_transition?(transition)
    tuple = Workflow.process_transition(transition)
    !AllowedStatus.find_by_workflow_id_and_status_id_and_next_status_id(id, tuple[:current].to_i, tuple[:next].to_i).blank?
  end

  def self.process_transition(transition)
    tuple = Hash.new
    _col = transition.split('_')
    tuple[:current] = _col[0]
    tuple[:next] = _col[1]
    tuple
  end

  def assigned_to?(task)
    self == task.workflow
  end

  def assign_to_tasks(tasks)
    Task.transaction do
      # reset current workflow assignment
      Task.find_all_by_workflow_id(id).each do |task|
        task.workflow_id = nil
        task.save
      end

      unless tasks.blank?
        tasks.each do |task|
          task = Task.find(task.to_i)
          task.workflow_id = id
          task.save
        end
      end
    end
  end

  def next_statuses_of(current_status)
    allowed_statuses = AllowedStatus.all(:conditions => ["workflow_id = ? and status_id = ?", id, current_status.id])
    next_statuses = []
    allowed_statuses.each do |as|
      next_statuses << as.next_status
    end
    next_statuses
  end
end
