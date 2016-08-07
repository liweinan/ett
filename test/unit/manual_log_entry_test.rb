# == Schema Information
#
# Table name: manual_log_entries
#
#  id                 :integer          not null, primary key
#  who_id             :integer
#  start_time         :datetime
#  end_time           :datetime
#  created_at         :datetime
#  updated_at         :datetime
#  package_id         :integer
#  weekly_workload_id :integer
#

require 'test_helper'

class ManualLogEntryTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
