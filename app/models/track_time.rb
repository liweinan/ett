class TrackTime < ActiveRecord::Base

  belongs_to :status
  belongs_to :package
end
