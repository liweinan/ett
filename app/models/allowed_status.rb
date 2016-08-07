# == Schema Information
#
# Table name: allowed_statuses
#
#  id             :integer          not null, primary key
#  workflow_id    :integer
#  status_id      :integer
#  next_statuses  :text
#  created_at     :datetime
#  updated_at     :datetime
#  next_status_id :integer
#

class AllowedStatus < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :current_status, :class_name => 'Status', :foreign_key => 'status_id'
  belongs_to :next_status, :class_name => 'Status', :foreign_key => 'next_status_id'
end

