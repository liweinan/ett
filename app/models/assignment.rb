class Assignment < ActiveRecord::Base
  belongs_to :package
  belongs_to :mark
end
