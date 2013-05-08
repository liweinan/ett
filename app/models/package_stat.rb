class PackageStat < ActiveRecord::Base
  belongs_to :weekly_workload, :class_name => "WeeklyWorkload", :foreign_key => "workload_id"
  has_many :label_stats, :class_name => "LabelStat", :foreign_key => "package_stat_id", :dependent => :destroy
  has_many :worktime_stats, :class_name => "WorktimeStat", :foreign_key => "package_stat_id", :dependent => :destroy  
end
