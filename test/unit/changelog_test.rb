# == Schema Information
#
# Table name: changelogs
#
#  id         :integer          not null, primary key
#  package_id :integer
#  changed_by :integer
#  category   :string(255)
#  references :string(255)
#  from_value :text
#  to_value   :text
#  changed_at :datetime
#

require 'test_helper'

class ChangelogTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
