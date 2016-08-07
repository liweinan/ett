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

class BrewNvr < ActiveRecord::Base
  belongs_to :package
end
