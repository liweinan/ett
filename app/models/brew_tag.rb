class BrewTag < ActiveRecord::Base
#  acts_as_tree
  validates_presence_of :name
  validates_uniqueness_of :name
  
  default_value_for :can_show, 'Yes'

  has_many :marks, :dependent => :destroy
  has_many :packages, :dependent => :destroy
  has_many :labels, :dependent => :destroy

  has_many :component_views
  has_many :components, :through => :component_views

  has_one :setting, :class_name => "Setting", :foreign_key => "brew_tag_id"

  acts_as_textiled :description

  LINK = {:tag => 0, :package => 1}

  def self.brew_tags_to_ids(brew_tags)
    brew_tag_ids = []
    brew_tags.each do |tag|
      brew_tag_ids << tag.id
    end
    brew_tag_ids
  end

  def self.all_that_have_package_with_name(name)
    BrewTag.all(:conditions => ["id in (select brew_tag_id from packages where name = ?)", name])
  end

end
