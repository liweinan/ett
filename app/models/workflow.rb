# == Schema Information
#
# Table name: workflows
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  start_status_id :integer
#

class Workflow < ActiveRecord::Base
  belongs_to :start_status, :class_name => 'Status',
             :foreign_key => 'start_status_id'

  has_many :allowed_statuses
  has_many :tasks
  has_many :start_status_workflows

  validates_presence_of :name

  # TODO: this method should be surrounded with a transaction
  def update_transitions(transitions)
    return if transitions.blank?

    # TODO: this nested transaction should merge with the transaction in caller
    Workflow.transaction do
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

  def update_start_statuses(start_status_ids)
    start_status_workflows.each {|wkf| wkf.destroy }
    start_status_ids.each do |status_id|
      start_status_workflows.create :status_id => status_id.to_i
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
        unless task.readonly?
          task.workflow_id = nil
          task.save
        end
      end

      unless tasks.blank?
        tasks.each do |task|
          task = Task.find(task.to_i)
          unless task.readonly?
            task.workflow_id = id
            task.save
          end
        end
      end
    end
  end

  def next_statuses_of(current_status)
    allowed_statuses = AllowedStatus.all(:conditions => ['workflow_id = ? and status_id = ?', id, current_status.id])
    next_statuses = []
    allowed_statuses.each do |as|
      next_statuses << as.next_status
    end
    next_statuses
  end
end
