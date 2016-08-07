# == Schema Information
#
# Table name: statuses
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  task_id         :integer
#  created_at      :datetime
#  updated_at      :datetime
#  global          :string(255)
#  can_select      :string(255)
#  can_show        :string(255)
#  code            :string(255)
#  style           :text
#  is_track_time   :string(255)
#  is_finish_state :string(255)
#  can_change_code :string(255)
#

require 'test_helper'

class StatusTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
