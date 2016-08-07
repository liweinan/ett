# == Schema Information
#
# Table name: worktime_stats
#
#  id              :integer          not null, primary key
#  package_stat_id :integer
#  user_id         :integer
#  minutes         :integer
#  time_span       :text
#  created_at      :datetime
#  updated_at      :datetime
#

require 'test_helper'

class WorktimeStatTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
