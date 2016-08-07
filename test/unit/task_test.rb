# == Schema Information
#
# Table name: tasks
#
#  id                      :integer          not null, primary key
#  name                    :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  description             :text
#  can_show                :string(255)
#  total_manual_track_time :integer
#  candidate_tag           :string(255)
#  target_release          :string(255)
#  tag_version             :string(255)
#  milestone               :string(255)
#  advisory                :string(255)
#  workflow_id             :integer
#  prod                    :string(255)
#  active                  :string(255)
#  repository              :string(255)
#  frozen_state            :string(255)
#  allow_non_existent_pkgs :boolean
#  allow_non_shipped_pkgs  :boolean
#  previous_version_tag    :string(255)
#  build_branch            :string(255)
#

require 'test_helper'

class TaskTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
