class WeeklyWorkload < ActiveRecord::Base
  has_many :package_stats, :class_name => "PackageStat", :foreign_key => "weekly_workload_id", :dependent => :destroy
end
