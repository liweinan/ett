class AutoSumDetail < ActiveRecord::Base
  belongs_to :weekly_workload
  belongs_to :status
  default_value_for :minutes, 0
end
