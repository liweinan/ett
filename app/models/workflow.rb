class Workflow < ActiveRecord::Base
  has_many :allowed_statuses
  validates_presence_of :name

  def update_transitions(transitions) # this method should be surrounded with a transaction
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
end
