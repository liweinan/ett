# == Schema Information
#
# Table name: brew_nvrs
#
#  id         :integer          not null, primary key
#  package_id :integer
#  nvr        :string(255)
#  distro     :string(255)
#  created_at :datetime
#  updated_at :datetime
#  link       :string(255)
#

require 'test_helper'

class BrewNvrTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
