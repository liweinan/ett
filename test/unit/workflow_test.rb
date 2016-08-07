# == Schema Information
#
# Table name: workflows
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  start_status_id :integer
#

require 'test_helper'

class WorkflowTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
