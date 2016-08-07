# == Schema Information
#
# Table name: task_group_to_tasks
#
#  id            :integer          not null, primary key
#  task_group_id :integer
#  task_id       :integer
#  created_at    :datetime
#  updated_at    :datetime
#

require 'test_helper'

class TaskGroupToTaskTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
