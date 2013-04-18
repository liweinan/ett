class ManualLogEntry < ActiveRecord::Base
  belongs_to :who, :class_name => "User", :foreign_key => "who_id"
  belongs_to :package
end
