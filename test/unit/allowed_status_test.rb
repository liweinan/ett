# == Schema Information
#
# Table name: allowed_statuses
#
#  id             :integer          not null, primary key
#  workflow_id    :integer
#  status_id      :integer
#  next_statuses  :text
#  created_at     :datetime
#  updated_at     :datetime
#  next_status_id :integer
#

require 'test_helper'

class AllowedStatusTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
