class BzBug < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "creator_id"
  belongs_to :package, :class_name => "Package", :foreign_key => "package_id"

  BZ_ACTIONS = {:movetoassigned => 'movetoassigned', :movetomodified => 'movetomodified', :accepted => 'accepted', :outofdate => 'outofdate', :done => 'done'}
  BZ_STATUS = {:new => "NEW", :assigned => "ASSIGNED", :post => "POST", :modified => "MODIFIED", :onqa => "ON_QA", :verified => "VERIFIED", :ondev => "ON_DEV"}

  default_value_for :bz_status, 'NEW'
  default_value_for :bz_action, BZ_ACTIONS[:done]
  default_value_for :last_synced_at, Time.now

  def self.create_from_bz_info(bz_info, package_id, current_user)
    bz_id = bz_info["id"]
    summary = bz_info["summary"]
    bz_status = bz_info["status"]
    bz_bug = BzBug.new
    bz_bug.package_id = package_id
    bz_bug.bz_id = bz_id
    bz_bug.summary = summary
    bz_bug.bz_status = bz_status
    bz_bug.creator_id = current_user.id
    bz_bug.save
    bz_bug
  end

  def self.update_from_bz_info(bz_info, bz_bug)
    bz_bug.bz_id = bz_info["id"]
    bz_bug.summary = bz_info["summary"]
    bz_bug.bz_status = bz_info["status"]
    bz_bug.last_synced_at = Time.now
    bz_bug.save
    bz_bug
  end
end

