# == Schema Information
#
# Table name: weekly_workloads
#
#  id            :integer          not null, primary key
#  task_id       :integer
#  start_of_week :datetime
#  end_of_week   :datetime
#  package_count :integer
#  manual_sum    :integer
#  created_at    :datetime
#  updated_at    :datetime
#

require 'test_helper'

class WeeklyWorkloadTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
