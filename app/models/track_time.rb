# == Schema Information
#
# Table name: track_times
#
#  id            :integer          not null, primary key
#  status_id     :integer
#  package_id    :integer
#  time_consumed :integer
#

class TrackTime < ActiveRecord::Base

  belongs_to :status
  belongs_to :package
end
