class WorktimeStat < ActiveRecord::Base
  belongs_to :package_stat, :class_name => "PackageStat", :foreign_key => "package_stat_id"
  default_value_for :minutes, 0
end
