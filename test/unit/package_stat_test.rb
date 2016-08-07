# == Schema Information
#
# Table name: package_stats
#
#  id                 :integer          not null, primary key
#  weekly_workload_id :integer
#  package_id         :integer
#  user_id            :integer
#  minutes            :integer
#  created_at         :datetime
#  updated_at         :datetime
#

require 'test_helper'

class PackageStatTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
