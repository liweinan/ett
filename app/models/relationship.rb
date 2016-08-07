# == Schema Information
#
# Table name: relationships
#
#  id         :integer          not null, primary key
#  from_name  :string(255)
#  is_global  :string(255)
#  task_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  to_name    :string(255)
#  name       :string(255)
#

class Relationship < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  
  default_value_for :is_global, 'Yes'

  def self.clone_relationship
    Relationship.find_by_name('clone')
  end

end
