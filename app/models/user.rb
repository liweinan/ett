class User < ActiveRecord::Base
  has_many :packages
  validates_uniqueness_of :name
  validates_uniqueness_of :email
  validates_presence_of :name
  validates_presence_of :email

  default_value_for :can_manage, "No"

  def self.find_by_name_or_email(id)
    user = nil
    if id.count("@") > 0
      user = User.find_by_email(id)
    else
      user = User.find_by_name(id)
    end
    user
  end
end
