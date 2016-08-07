# == Schema Information
#
# Table name: status_stats
#
#  id              :integer          not null, primary key
#  package_stat_id :integer
#  status_id       :integer
#  user_id         :integer
#  minutes         :integer
#  created_at      :datetime
#  updated_at      :datetime
#

require 'test_helper'

class StatusStatTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
