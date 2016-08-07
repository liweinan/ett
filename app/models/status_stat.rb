# == Schema Information
#
# Table name: status_stats
#
#  id              :integer          not null, primary key
#  package_stat_id :integer
#  status_id       :integer
#  user_id         :integer
#  minutes         :integer
#  created_at      :datetime
#  updated_at      :datetime
#

class StatusStat < ActiveRecord::Base
  belongs_to :package_stat, :class_name => 'PackageStat', :foreign_key => 'package_stat_id'
  belongs_to :status
  default_value_for :minutes, 0
end
