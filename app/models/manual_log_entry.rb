# == Schema Information
#
# Table name: manual_log_entries
#
#  id                 :integer          not null, primary key
#  who_id             :integer
#  start_time         :datetime
#  end_time           :datetime
#  created_at         :datetime
#  updated_at         :datetime
#  package_id         :integer
#  weekly_workload_id :integer
#

class ManualLogEntry < ActiveRecord::Base
  belongs_to :who, :class_name => "User", :foreign_key => "who_id"
  belongs_to :package
end
