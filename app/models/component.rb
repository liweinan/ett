class Component < ActiveRecord::Base
#  has_and_belongs_to_many :packages
  has_and_belongs_to_many :tasks
  
  has_many :component_views, :dependent => :destroy
  has_many :tasks, :through => :component_views

  validates_presence_of :name
  validates_uniqueness_of :name

end
