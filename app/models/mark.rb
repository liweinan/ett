class Mark < ActiveRecord::Base
  validates_presence_of :key
  validates_presence_of :product_id
  belongs_to :product
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
