# == Schema Information
#
# Table name: worktime_stats
#
#  id              :integer          not null, primary key
#  package_stat_id :integer
#  user_id         :integer
#  minutes         :integer
#  time_span       :text
#  created_at      :datetime
#  updated_at      :datetime
#

class WorktimeStat < ActiveRecord::Base
  belongs_to :package_stat, :class_name => 'PackageStat', :foreign_key => 'package_stat_id'
  default_value_for :minutes, 0
end
