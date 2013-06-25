class Product < ActiveRecord::Base
#  acts_as_tree
  validates_presence_of :name
  validates_uniqueness_of :name
  
  default_value_for :can_show, 'Yes'
  default_value_for :total_manual_track_time, 0

  has_many :marks, :dependent => :destroy
  has_many :packages, :dependent => :destroy
  has_many :labels, :dependent => :destroy

  has_many :component_views
  has_many :components, :through => :component_views

  has_one :setting, :class_name => "Setting", :foreign_key => "product_id"

  acts_as_textiled :description

  LINK = {:tag => 0, :package => 1}

  def self.products_to_ids(products)
    product_ids = []
    products.each do |product|
      product_ids << product.id
    end
    product_ids
  end

  def self.all_that_have_package_with_name(name)
    Product.all(:conditions => ["id in (select product_id from packages where name = ?)", name])
  end

end
