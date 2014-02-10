class StartStatusWorkflow < ActiveRecord::Base
  belongs_to :workflows
  belongs_to :status, :class_name => 'Status', :foreign_key => 'status_id'
end
