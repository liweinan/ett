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
      bz_id # else part
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
    puts BzBug.bz_bug_creation_uri
    response = Net::HTTP.post_form(BzBug.bz_bug_creation_uri, parameters)

    if response.class == Net::HTTPCreated
      #  @response.body
      # "BZ#999999: Upgrade jboss-aggregator to 7.2.0.Final-redhat-7 (MOCK)"
      bug_info = BzBug.extract_bz_bug_info(response.body)
      bz_id = bug_info[:bz_id]
      response = BzBug.query_bz_bug_info(bz_id, parameters['userid'], parameters['pwd'])

      if response.class == Net::HTTPOK
        bz_info = JSON.parse(response.body)
        BzBug.create_from_bz_info(bz_info, package_id, current_user, os)
      end
    end
    response
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

  # Get the mead scheduler endpoint for updating current bugzillas. The endpoint
  # depends on whether we are in production or development.
  #
  # Returns: string
  def self.bz_bug_status_update_url
    if Rails.env.production?
      return APP_CONFIG['bz_bug_status_update_url']
    else
      return APP_CONFIG['bz_bug_status_update_url_mocked']
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

  # TODO: maybe make it a method function instead?
  def self.query_bz_bug_info(bz_id, user, pwd)
    uri = URI.parse(URI.encode(APP_CONFIG['mead_scheduler']))
    req = Net::HTTP::Get.new("/mead-bzbridge/bug/#{bz_id}?userid=#{user}&pwd=#{pwd}")
    req['Accept'] = 'application/json'
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
  end

end
