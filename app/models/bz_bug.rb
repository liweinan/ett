class BzBug < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "creator_id"
  belongs_to :package, :class_name => "Package", :foreign_key => "package_id"

  BZ_ACTIONS = {:movetoassigned => 'movetoassigned',
                :movetomodified => 'movetomodified',
                :accepted => 'accepted',
                :outofdate => 'outofdate',
                :done => 'done'}
  BZ_STATUS = {:new => "NEW",
               :assigned => "ASSIGNED",
               :post => "POST",
               :modified => "MODIFIED",
               :onqa => "ON_QA",
               :verified => "VERIFIED",
               :ondev => "ON_DEV"}

  default_value_for :bz_status, 'NEW'
  default_value_for :bz_action, BZ_ACTIONS[:done]
  default_value_for :last_synced_at, Time.now
  default_value_for :is_in_errata, "NO"

  # Creates a new bz_bug entry in the database based on the information provided
  #
  # Params:
  # +bz_info+:: hash of key and value strings. The following keys are required:
  #             id, summary, status, assignee, component, keywords (array of
  #             strings)
  # +package_id+:: integer -> id of package owning this bugzilla
  # +current_user+:: User object -> user owning this bugzilla
  # +os+:: string -> bugzilla is categorized according to which os version they
  #        are created. Default is 'el6'
  #
  # Returns: the bugzilla object
  def self.create_from_bz_info(bz_info, package_id, current_user, os='el6')

    bz_bug = BzBug.new

    bz_bug.package_id = package_id
    bz_bug.creator_id = current_user.id
    bz_bug.os_arch = os

    bz_bug.bz_id = bz_info["id"]
    bz_bug.summary = bz_info["summary"]
    bz_bug.bz_status = bz_info["status"]
    bz_bug.bz_assignee = bz_info["assignee"]
    bz_bug.component = bz_info["component"]
    bz_bug.keywords = bz_info["keywords"].join(',')

    bz_bug.save
    bz_bug
  end

  # Update a current bugzilla row entry in the database
  #
  # Params:
  # +bz_info+:: hash of key and value strings. The following keys are required:
  #             id, summary, status, assignee, component, keywords (array of
  #             strings)
  # +bz_bug+:: BzBug object/row to be updated
  #
  # Returns: the updated bugzilla object
  def self.update_from_bz_info(bz_info, bz_bug)
    bz_bug.bz_id = bz_info["id"]
    bz_bug.summary = bz_info["summary"]
    bz_bug.bz_status = bz_info["status"]
    bz_bug.bz_assignee = bz_info["assignee"]
    bz_bug.component = bz_info["component"]
    bz_bug.keywords = bz_info["keywords"].join(',')
    bz_bug.last_synced_at = Time.now

    bz_bug.save
    bz_bug
  end

  # Return the bugzilla id with a tick mark string if the bugzilla is considered
  # to be inside an errata, otherwise, omit the tick mark string and just print
  # the id
  #
  # The bugzilla is considered to be in the errata if its is_in_errata column is
  # not empty or has the value 'YES'. Note that the default value for
  # is_in_errata is 'NO'
  #
  # Returns: string
  def bz_id_and_is_in_errata
    return bz_id + " ✔" if !is_in_errata.blank? && is_in_errata == "YES"
    return bz_id # else part
  end
end
