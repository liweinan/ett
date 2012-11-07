class User < ActiveRecord::Base
  has_many :packages
  validates_uniqueness_of :name
  validates_uniqueness_of :email
  validates_presence_of :name
  validates_presence_of :email

  default_value_for :can_manage, "No"
end
