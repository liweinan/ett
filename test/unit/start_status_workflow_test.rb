# == Schema Information
#
# Table name: start_status_workflows
#
#  id          :integer          not null, primary key
#  workflow_id :integer
#  status_id   :integer
#  created_at  :datetime
#  updated_at  :datetime
#

require 'test_helper'

class StartStatusWorkflowTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
