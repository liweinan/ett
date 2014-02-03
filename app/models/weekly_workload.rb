class WeeklyWorkload < ActiveRecord::Base
  has_many :package_stats, :class_name => 'PackageStat',
           :foreign_key => 'weekly_workload_id', :dependent => :destroy,
           :order => 'user_id'
  has_many :auto_sum_details, :class_name => 'AutoSumDetail',
           :foreign_key => 'weekly_workload_id', :dependent => :destroy
  belongs_to :task
  default_value_for :manual_sum, 0
  default_value_for :package_count, 0
end
