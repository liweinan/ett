class AllowedStatus < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :current, :class_name => "Status", :foreign_key => "status_id"
  has_many :next, :class_name => "Status", :foreign_key => "next_status_id"

end

