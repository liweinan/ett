class TrackTime < ActiveRecord::Base

  belongs_to :label
  belongs_to :package
end
