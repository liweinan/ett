# == Schema Information
#
# Table name: package_stats
#
#  id                 :integer          not null, primary key
#  weekly_workload_id :integer
#  package_id         :integer
#  user_id            :integer
#  minutes            :integer
#  created_at         :datetime
#  updated_at         :datetime
#

class PackageStat < ActiveRecord::Base
  belongs_to :weekly_workload, :class_name => 'WeeklyWorkload', :foreign_key => 'workload_id'
  belongs_to :package, :class_name => 'Package', :foreign_key => 'package_id'
  belongs_to :assignee, :class_name => 'User', :foreign_key => 'user_id'
  has_many :status_stats, :class_name => 'StatusStat', :foreign_key => 'package_stat_id', :dependent => :destroy
  has_many :worktime_stats, :class_name => 'WorktimeStat', :foreign_key => 'package_stat_id', :dependent => :destroy
  default_value_for :minutes, 0

end
