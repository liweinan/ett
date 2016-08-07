# == Schema Information
#
# Table name: auto_log_entries
#
#  id                 :integer          not null, primary key
#  who_id             :integer
#  status_id          :integer
#  start_time         :datetime
#  end_time           :datetime
#  package_id         :integer
#  weekly_workload_id :integer
#

class AutoLogEntry < ActiveRecord::Base
  belongs_to :who, :class_name => 'User', :foreign_key => 'who_id'
  belongs_to :status, :class_name => 'Status', :foreign_key => 'status_id'
  belongs_to :package
end
