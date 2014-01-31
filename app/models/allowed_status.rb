class AllowedStatus < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :current_status, :class_name => 'Status', :foreign_key => 'status_id'
  belongs_to :next_status, :class_name => 'Status', :foreign_key => 'next_status_id'
end

