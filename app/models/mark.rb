class Mark < ActiveRecord::Base
  validates_presence_of :key
  validates_presence_of :brew_tag_id
  belongs_to :brew_tag
  has_many :assignments
  has_many :packages, :through => :assignments

  def packages_can_show
    __packages = []
    self.packages.each do |package|
      if package.label.blank? || package.label.can_show?
        __packages << package
      end
    end
    __packages
  end
end
