# == Schema Information
#
# Table name: relationships
#
#  id         :integer          not null, primary key
#  from_name  :string(255)
#  is_global  :string(255)
#  task_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  to_name    :string(255)
#  name       :string(255)
#

require 'test_helper'

class RelationshipTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
