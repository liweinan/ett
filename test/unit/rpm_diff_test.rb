# == Schema Information
#
# Table name: rpm_diffs
#
#  id             :integer          not null, primary key
#  in_errata      :string(255)
#  rpmdiff_status :string(255)
#  rpmdiff_id     :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  nvr_in_errata  :string(255)
#  package_id     :integer
#  distro         :string(255)
#

require 'test_helper'

class RpmDiffTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
