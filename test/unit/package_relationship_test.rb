# == Schema Information
#
# Table name: package_relationships
#
#  id              :integer          not null, primary key
#  from_package_id :integer
#  to_package_id   :integer
#  relationship_id :integer
#  created_at      :datetime
#  updated_at      :datetime
#

require 'test_helper'

class PackageRelationshipTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
