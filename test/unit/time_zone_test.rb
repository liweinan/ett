# == Schema Information
#
# Table name: time_zones
#
#  id        :integer          not null, primary key
#  tz_offset :float
#  text      :string(255)
#

require 'test_helper'

class TimeZoneTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
