# == Schema Information
#
# Table name: time_zones
#
#  id        :integer          not null, primary key
#  tz_offset :float
#  text      :string(255)
#

class TimeZone < ActiveRecord::Base
end
