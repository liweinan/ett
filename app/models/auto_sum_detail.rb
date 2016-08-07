# == Schema Information
#
# Table name: auto_sum_details
#
#  id                 :integer          not null, primary key
#  weekly_workload_id :integer
#  status_id          :integer
#  minutes            :integer
#  created_at         :datetime
#  updated_at         :datetime
#

class AutoSumDetail < ActiveRecord::Base
  belongs_to :weekly_workload
  belongs_to :status
  default_value_for :minutes, 0
end
