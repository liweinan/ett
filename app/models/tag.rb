# == Schema Information
#
# Table name: tags
#
#  id         :integer          not null, primary key
#  key        :string(255)
#  value      :text
#  created_at :datetime
#  updated_at :datetime
#  task_id    :integer
#

class Tag < ActiveRecord::Base
  validates_presence_of :key
  validates_presence_of :task_id
  belongs_to :task
  has_many :assignments
  has_many :packages, :through => :assignments

  def packages_can_show
    __packages = []
    self.packages.each do |package|
      if package.status.blank? || package.status.can_show?
        __packages << package
      end
    end
    __packages
  end
end
