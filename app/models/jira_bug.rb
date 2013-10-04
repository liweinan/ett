#
# This class will model a JIRA issue. It'll contain all records related to a JIRA issue, and it will also define all methods needed
# for creating, updating, syncing JIRA issues in the DB and also for sending RESTful requests to the JIRA server.
#
class JiraBug < ActiveRecord::Base
  require 'rubygems'
  require 'net/http'
  require 'json'

  belongs_to :creator, :class_name => "User", :foreign_key => "creator_id"
  belongs_to :package, :class_name => "Package", :foreign_key => "package_id"

  # http://hostname/rest/api/2/<resource-name>
  JIRA_BASE_URI = https://issues.jboss.org/rest/api/2
  JIRIA_AUTH_URI = https://issues.jboss.org/rest/auth
  JIRA_RESOURCES = {:issue => "issue"} # TODO: verify which JIRA resources are needed with huwang

  #JIRA_ACTIONS = {:movetoassigned => 'movetoassigned', :movetomodified => 'movetomodified', :accepted => 'accepted', :outofdate => 'outofdate', :done => 'done'}
  JIRA_FIELDS = { 
    :project => "key", 
    :summary => "", 
    :issuetype => "name", 
    :reporter => "name", 
    :assignee => "id", 
    :priority => "id", 
    :security => "id", 
    :versions => "id", 
    :fixVersions => "id", 
    :environment => "", 
    :description => ""}

  JIRA_INFO = [ "id", "key", "self" ]

  # Verify that these are all correct JIRA statuses:
  JIRA_STATUS = {:open => "Open", :resolved => "Resolved", :closed => "Closed", :in_progress => "In Progress", :reopened => "Reopened"}

  default_value_for :jira_status, 'NEW'
  default_value_for :jira_action, JIRA_ACTIONS[:done]
  default_value_for :last_synced_at, Time.now
  default_value_for :is_in_errata, "NO"


  # DB JIRA Issue methods: create, update.

  # Create a new instance of a jira bug from the info passed to us from a RESTful
  # request to JIRA.
  # Save this new instance into the database.
  def self.create_from_jira_info(jira_info, package_id, current_user)
    jiraBug = JiraBug.new
    jiraBug.package_id = package_id
    jiraBug.reporter = current_user.id
    jiraBug.type = jira_info["type"]
    jiraBug.priority = jira_info["priority"]
    jiraBug.components = jira_info["components"]

    jiraBug.save
    jiraBug
  end

  # Update a JIRA issue from the DB with info from a JIRA request 
  # and then save it to the DB.
  def self.update_from_jira_info(jira_info, jira_issue_id)
    # Grab whatever fields we need for this bug from the jira_info hash.
    jiraBug.save
    jiraBug
  end



  # JIRA RESTful request methods here.
  # See https://docs.atlassian.com/jira/REST/latest/ for request documentation.

  # Session authentication. 
  # Currently we can just put username:password 
  # int the request HEADer info.
  # But this is bad since they're sent unencrypted
  # so later we'll need to figure out how to do a proper
  # authentication using HTTP Cookies.
  # See here for tutorial:
  # https://developer.atlassian.com/display/JIRADEV/JIRA+REST+API+%28Alpha%29+Tutorial#JIRARESTAPI%28Alpha%29Tutorial-UserAuthentication
  def authenticate(username, password)

  end

  # Returns the URI for a given resource:
  # A resource can be 'issue', (just that for now)
  def make_jira_uri(resource)
    JiraBug.JIRA_BASE_URI + JIRA_RESOURCES[resource]
  end

  # Send a RESTful request to create a new issue in JIRA.
  # See the following docs for details:
  # https://docs.atlassian.com/jira/REST/latest/#idp1846544
  def create
    # params is a dictionary that comes straight from the 
    # current package info page where the 'create jira issue'
    # button is pressed.
    begin_check_param
    check_param_user(params)
    check_param_pwd(params)
    check_param_ver(params)
    end_check_param
    # create parameters hash
    parameters = {
      'userid' => params[:user],
      'pwd' => params[:pwd]
    # TODO: Find out the params keys for the JIRA fields listed below
    # Must fill (From Hui Wang):
    # Project: default is JBoss Enterprise Application Platform
    # Issue Type: default is task
    # Summary: user need to fill some info [ see bz for options ]
    # Assignee: from package info 'assignee'
    # Reporter: probably same as assignee
    # Priority: default is Critical
    # Affect version/s: e.g EAP_EWP 5.2.0.ER1
    # Fix Version/s: e.g EAP_EWP 5.2.0.ER2
    # Security Level: default is Public
    }

    # Put together URI:
    uri = make_jira_uri("issue")
    
    # Create HTTP request and get response
    @response = Net::HTTP.post_form(uri, parameters)

    # Response Handler
    if @response.class == Net::HTTPOK
      # 200 returns json the "id", a "key", and a "self" (link to issue).

    elsif @response.class == Net::HTTPBadRequest
      # 400 returns json with list of "errorMessages" and dictionary "errors"
      
    end


  end

  # PUT (update) fields on an existing JIRA issue.
  # See: https://docs.atlassian.com/jira/REST/latest/#idp1908272
  def update
    # Put parameters together.
    parameters = {
      # Stuff we're updating.
    }
    # Make JSON out of parameters.
    json = create_json_from_dict(parameters)

    # Put together URI of the form: 
    # http://hostname/rest/api/2/issue/{issueIdOrKey}
    uri = make_jira_uri("issue") + params[:jira_issue_id]
    
    # Create HTTP request and get response
    @response = Net::HTTP.put_form(uri, json)

    # Response Handler
    if @response.class == Net::HTTPOK
      # 200 returns json the "id", a "key", and a "self" (link to issue).

    elsif @response.class == Net::HTTPBadRequest
      # 404 
      
    end

  end

  # GET an issue from JIRA.
  # See https://docs.atlassian.com/jira/REST/latest/#idp1908272
  def get

    # Put together URI of the form: 
    # http://hostname/rest/api/2/issue/{issueIdOrKey}
    uri = make_jira_uri("issue") + params[:jira_issue_id]
    
    # Create HTTP request and get response
    @response = Net::HTTP.get_response(uri, json)

    # Response Handler
    if @response.class == Net::HTTPOK
      # 200 returns json the "id", a "key", and a "self" (link to issue).

    elsif @response.class == Net::HTTPNotFound
      # 404 for 'not found' or user doesn't 'have permission'
      
    end

  end

# Create a correctly formatted json object from a 
  # dictionary of parameters. This JSON must
  # adhere to the issue POST requirements:
  # https://docs.atlassian.com/jira/REST/latest/#idp1846544
  def create_json_from_dict(parameters)
    # 
    jira_map = {}
    jira_map[:fields]={}

    # All the fields get put into "fields"
    parameters.each do |p, v|
      #puts print_key_value(p,v)
      # If it's in "fields"
      if JIRA_FIELDS.key?(p)
        if JIRA_FIELDS[p].empty?
          jira_map[:fields][p]=v
        else
          jira_map[:fields][p]={}
          jira_map[:fields][p][JIRA_FIELDS[p]]=v
        end
        #jira_map[:fields][ p => { JIRA_FIELDS[p] => v }]
      end

      # For other non-field JIRA params:
      if JIRA_INFO.include? p
        jira_map[p]=v
      end
    end 

    jira_map
  end

   # Takes a jira style JSON and flattens it into
  # a regular dictionary.
  def create_dict_from_json(jira_json)
    d = {}

    jira_json.each do |k,v|
      # Handle field
      if k == :fields
        v.each do |f,i|
          if JIRA_FIELDS[f].empty?
            d[f]=v[f]
          else
            d[f]=i[JIRA_FIELDS[f]]
        end
        end
      # Handle others
      else 
        d[k]=v
      end
    end
    d
  end

end

