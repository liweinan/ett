class AllowedStatus < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :status
end
