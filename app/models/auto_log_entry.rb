class AutoLogEntry < ActiveRecord::Base
  belongs_to :who, :class_name => "User", :foreign_key => "who_id"
  belongs_to :label, :class_name => "Label", :foreign_key => "label_id"
end
