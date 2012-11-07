class Relationship < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  
  default_value_for :is_global, 'Yes'

  def self.clone_relationship
    Relationship.find_by_name("clone")
  end

end
