# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  email          :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  can_manage     :string(255)
#  tz_id          :integer
#  password       :string(255)
#  bugzilla_email :string(255)
#  reset_code     :string(255)
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
