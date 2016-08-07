# == Schema Information
#
# Table name: start_status_workflows
#
#  id          :integer          not null, primary key
#  workflow_id :integer
#  status_id   :integer
#  created_at  :datetime
#  updated_at  :datetime
#

class StartStatusWorkflow < ActiveRecord::Base
  belongs_to :workflows
  belongs_to :status, :class_name => 'Status', :foreign_key => 'status_id'
end
