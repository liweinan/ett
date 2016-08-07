# == Schema Information
#
# Table name: bz_bugs
#
#  id             :integer          not null, primary key
#  bz_id          :string(255)
#  package_id     :integer
#  creator_id     :integer
#  created_at     :datetime
#  updated_at     :datetime
#  summary        :string(255)
#  bz_status      :string(255)
#  last_synced_at :datetime
#  bz_action      :string(255)
#  bz_assignee    :string(255)
#  component      :string(255)
#  keywords       :string(255)
#  is_in_errata   :string(255)
#  os_arch        :string(255)
#

require 'net/http'
require 'json'

class BzBug < ActiveRecord::Base
  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
  belongs_to :package, :class_name => 'Package', :foreign_key => 'package_id'

  BZ_ACTIONS = {:movetoassigned => 'movetoassigned',
                :movetomodified => 'movetomodified',
                :accepted => 'accepted',
                :outofdate => 'outofdate',
                :done => 'done'}
  BZ_STATUS = {:new => 'NEW',
               :assigned => 'ASSIGNED',
               :post => 'POST',
               :modified => 'MODIFIED',
               :onqa => 'ON_QA',
               :verified => 'VERIFIED',
               :ondev => 'ON_DEV'}

  default_value_for :bz_status, 'NEW'
  default_value_for :bz_action, BZ_ACTIONS[:done]
  default_value_for :last_synced_at, Time.now
  default_value_for :is_in_errata, 'NO'

  # Creates a new bz_bug entry in the database based on the information provided
  #
  # Parameter is generally obtained from querying the bugzilla using the
  # appropriate method
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

    BzBug.update_from_bz_info(bz_info, bz_bug)
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
    bz_bug.bz_id = bz_info['id']
    bz_bug.summary = bz_info['summary']
    bz_bug.bz_status = bz_info['status']
    bz_bug.bz_assignee = bz_info['assignee']
    bz_bug.component = bz_info['component']
    bz_bug.keywords = bz_info['keywords'].join(',')
    bz_bug.last_synced_at = Time.now

    upgrade_bz_regex = /RHEL(\d+) RPMs: Upgrade/
    match_data = bz_bug.summary.match(upgrade_bz_regex)

    unless match_data.nil?
      os_arch = match_data[1]
      bz_bug.os_arch = "el" + os_arch
    end

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
    if !is_in_errata.blank? && is_in_errata == 'YES'
      bz_id + ' ✔'
    else
      bz_id
    end
  end

  # Create a bug to bugzilla and also create a new bz_bug object to the database
  #
  # Params:
  # +parameters+: hash of key strings and value strings
  #  Keys expected in parameters:
  #  pkg:         package name
  #  version:     version of the package to be upgraded
  #  release:     The target release
  #  tagversion:  The target version
  #  userid:      Just the username of user that will build package (e.g dcheung)
  #  pwd:         The password of the user (for bugzilla)
  #  summary:     The summary of the bugzilla to be created
  #  seealso:     [optional] optional bugzilla id to link to the bz we will
  #               create
  #  assignee:    The email of the assignee of this bugzilla
  def self.create_bzs_from_params(parameters, os, package_id, current_user)
    puts parameters
    bz_bug = nil
    puts BzBug.bz_bug_creation_uri
    response = Net::HTTP.post_form(BzBug.bz_bug_creation_uri, parameters)

    if response.class == Net::HTTPCreated
      #  @response.body
      # "BZ#999999: Upgrade jboss-aggregator to 7.2.0.Final-redhat-7 (MOCK)"
      bug_info = BzBug.extract_bz_bug_info(response.body)
      bz_id = bug_info[:bz_id]
      response = MeadSchedulerService.query_bz_bug_info(bz_id, parameters['userid'], parameters['pwd'])

      if response.class == Net::HTTPOK
        bz_info = JSON.parse(response.body)
        bz_bug = BzBug.create_from_bz_info(bz_info, package_id, current_user, os)
      end
    end
    [response, bz_bug]
  end

  # From assignee (User) object, determine the best email address of the
  # assignee
  #
  # Params:
  # +assignee+: User object that represents the assignee of a bugzilla
  #
  # Returns: string of email address of assignee, nil if assignee is nil
  def self.determine_bz_assignee_email(assignee)
    if assignee.blank?
      nil
    else
      if assignee.bugzilla_email.blank?
        assignee.email
      else
        assignee.bugzilla_email
      end
    end
  end

  # Get the URI object for creating/updating new bugzilla using the mead
  # scheduler REST API. The endpoint depends on whether we are in production or
  # development
  #
  # Returns: URI object representing the endpoint
  def self.bz_bug_creation_uri
    if Rails.env.production?
      return URI.parse(APP_CONFIG['bz_bug_creation_url'])
    else
      return URI.parse(APP_CONFIG['bz_bug_creation_url_mocked'])
    end
  end

  def self.extract_bz_bug_info(body)
    #  @response.body
    # "999999: Upgrade jboss-aggregator to 7.2.0.Final-redhat-7 (MOCK)"
    bug_info = Hash.new
    unless body.blank?
      bug_info[:bz_id] = body.scan(/^\d+/)[0].to_i
      bug_info[:summary] = body.split(/^\d+:\s*/)[1]
    end
    bug_info
  end

  # return a list of bzs belonging to that task and in the distro
  def self.find_bzs(task_id, distro)
    bzs = []
    task = Task.find(task_id)
    packages = task.packages.all

    packages.each do |package|
      package.upgrade_bz.each do |bz|
        bzs << bz if bz.os_arch == distro
      end
    end
    bzs
  end
end
