class User < ActiveRecord::Base
  has_many :packages
  validates_uniqueness_of :name
  validates_uniqueness_of :email
  validates_presence_of :name
  validates_presence_of :email
  belongs_to :tz, :class_name => 'TimeZone', :foreign_key => 'tz_id'
  attr_accessor :confirm_password
  default_value_for :can_manage, 'No'

  def self.find_by_name_or_email(id)
    user = nil
    if id.count('@') > 0
      user = User.find_by_email(id)
    else
      user = User.find_by_name(id)
    end
    user
  end

  def zone
    if tz.blank?
      nil
    else
      ActiveSupport::TimeZone[tz.tz_offset]
    end
  end

  def zone_name
    if tz.blank?
      return 'N/A'
    else
      tz.text
    end
  end

  def self.encrypt_password(password)
    return nil if password.blank?
    require 'digest/md5'
    Digest::MD5.hexdigest(password)
  end

  def password=(password)
    self[:password] = User.encrypt_password(password)
  end

  def make_token
    self.reset_code = Time.now.to_i
    self.save
  end

end
