class BzBug < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "creator_id"
  belongs_to :package, :class_name => "Package", :foreign_key => "package_id"
  default_value_for :bz_status, 'NEW'

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
end

