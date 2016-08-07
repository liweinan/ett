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

class RpmDiff < ActiveRecord::Base
  belongs_to :package
end
