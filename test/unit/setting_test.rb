# == Schema Information
#
# Table name: settings
#
#  id                   :integer          not null, primary key
#  recipients           :text
#  props                :integer
#  created_at           :datetime
#  updated_at           :datetime
#  task_id              :integer
#  actions              :integer
#  xattrs               :text
#  show_xattrs          :string(255)
#  enabled              :string(255)
#  enable_xattrs        :string(255)
#  default_tag          :string(255)
#  close_status_id      :integer
#  use_bz_integration   :string(255)
#  use_mead_integration :string(255)
#  use_jira_integration :string(255)
#

require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
