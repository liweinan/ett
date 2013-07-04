class Status < ActiveRecord::Base
  belongs_to :product
#  validates_presence_of :product_id
  validates_presence_of :name
  validates_uniqueness_of :code, :allow_nil => :true  

  default_value_for :global, 'N'
  default_value_for :can_select, 'Yes'
  default_value_for :can_show, 'Yes'
  default_value_for :can_change_code, 'Yes'
  default_value_for :is_track_time, 'Yes'
  default_value_for :style, ''
  default_value_for :is_finish_state, 'No'

  def is_global?
    self.global == 'Y'
  end

  def is_time_tracked?
    return is_track_time?
  end

  def is_track_time?
    if is_track_time.blank?
      return false
    end
    return is_track_time == 'Yes'
  end

  def can_show?
    self.can_show == 'Yes'
  end

  def self.deleted_status
    Status.find_by_code("deleted")
  end

  def self.find_all_can_select_only_in_global_scope
    Status.find(:all, :conditions => ["(global='Y') AND can_select='Yes'"], :order => "lower(name)")
  end

  def self.find_all_can_show_by_product_id_in_global_scope(product_id)
    Status.find(:all, :conditions => ["(product_id = ? OR global='Y') AND can_show='Yes'", product_id], :order => 'lower(name)')
  end

  def self.ids_can_show_by_product_name_in_global_scope(product_name)
    statuses = Status.find_all_can_show_by_product_id_in_global_scope(Product.find_by_name(product_name).id)
    __str = ""
    statuses.each do |status|
      __str << "#{status.id} ,"
    end
    __str[0..__str.size - 2]
  end

  def self.find_all_can_select_by_product_id_in_global_scope(product_id)
    Status.find(:all, :conditions => ["(product_id = ? or global='Y') AND can_select='Yes'", product_id], :order => "lower(name)")
  end

  def self.find_all_can_select_by_product_id(product_id)
    Status.find(:all, :conditions => ["(product_id = ?) AND can_select='Yes'", product_id], :order => "lower(name)")
  end

  def self.find_in_global_scope(status_name, product_name)
    status_id = -1
    global_status = Status.find(:first, :conditions => ["name = ? and global='Y'", status_name])
    if global_status == nil
      return Status.find_by_name_and_product_id(status_name, Product.find_by_name(product_name).id)
    else
      return global_status
    end
  end

  def can_change_code?
    can_change_code == 'Yes'
  end

  protected

  def validate
    status = Status.find_by_name_and_product_id(self.name.strip, self.product_id)
    if status == nil
      status = Status.find(:first, :conditions => ["global='Y' and name = ?", self.name.strip])
    end

    if status && status.id != self.id
      errors.add(:name, " - Status name cannot be duplicate under one product!")
    end
  end

end
