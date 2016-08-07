# == Schema Information
#
# Table name: auto_sum_details
#
#  id                 :integer          not null, primary key
#  weekly_workload_id :integer
#  status_id          :integer
#  minutes            :integer
#  created_at         :datetime
#  updated_at         :datetime
#

require 'test_helper'

class AutoSumDetailTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
