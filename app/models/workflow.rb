class Workflow < ActiveRecord::Base
  has_many :allowed_statuses
end
