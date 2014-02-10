class AutoLogEntry < ActiveRecord::Base
  belongs_to :who, :class_name => 'User', :foreign_key => 'who_id'
  belongs_to :status, :class_name => 'Status', :foreign_key => 'status_id'
  belongs_to :package
end
