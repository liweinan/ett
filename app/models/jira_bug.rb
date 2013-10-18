#
# This class will model a JIRA issue. It'll contain all records related to a JIRA issue, and it will also define all methods needed
# for creating, updating, syncing JIRA issues in the DB and also for sending RESTful requests to the JIRA server.
#
class JiraBug < ActiveRecord::Base
  require 'rubygems'
  require 'net/http'
  require 'net/https'
  require 'json'
  require 'uri'

  set_primary_key :key
  belongs_to :creator, :class_name => "User", :foreign_key => "creator_id"
  belongs_to :package, :class_name => "Package", :foreign_key => "package_id"

  # http://hostname/rest/api/2/<resource-name>
  JIRA_BASE_URI = "https://issues.jboss.org/rest/api/2/"
  JIRIA_AUTH_URI = "https://issues.jboss.org/rest/auth/"
  JIRA_RESOURCES = {:issue => "issue/"} # TODO: verify which JIRA resources are needed with huwang

  #JIRA_ACTIONS = {:movetoassigned => 'movetoassigned', :movetomodified => 'movetomodified', :accepted => 'accepted', :outofdate => 'outofdate', :done => 'done'}
  JIRA_FIELDS = { 
    :project => "key", 
    :summary => "", 
    :issuetype => "name", 
    :reporter => "name", 
    :assignee => "id", 
    :priority => "id", 
    :security => "id", 
    :versions => ["name"], 
    :fixVersions => ["name"], 
    :environment => "", 
    :description => "",
    :components => ["name"]}

  JIRA_INFO = [ :id, :key, :self ]

  # Verify that these are all correct JIRA statuses:
  JIRA_STATUS = {:open => "Open", :resolved => "Resolved", :closed => "Closed", :in_progress => "In Progress", :reopened => "Reopened"}

  #default_value_for :jira_status, 'NEW'
  #default_value_for :jira_action, JIRA_ACTIONS[:done]
  #default_value_for :last_synced_at, Time.now
  #default_value_for :is_in_errata, "NO"


  # DB JIRA Issue methods: create, update.

  # Create a new instance of a jira bug from the info passed to us from a RESTful
  # request to JIRA.
  # Save this new instance into the database.
  def self.create_from_jira_info(jira_info)
    jira_bug = JiraBug.new
    JiraBug.update_from_jira_info(jira_info, jira_bug)
  end

  # Update a JIRA issue from the DB with info from a JIRA request 
  # and then save it to the DB.
  def self.update_from_jira_info(jira_info, jira_bug)
    # Grab whatever fields we need for this bug from the jira_info hash.
    jira_bug.jid = jira_info["id"].to_i
    jira_bug.summary = jira_info["summary"]
    jira_bug.key = jira_info["key"]
    #jira_bug.package_id = package_id
    jira_bug.reporter = jira_info["reporter"]
    jira_bug.issuetype = jira_info["issuetype"]
    jira_bug.priority = jira_info["priority"]
    jira_bug.components = jira_info["components"].join(',')
    jira_bug.affected_versions = jira_info["versions"].join(',')
    jira_bug.affected_versions = jira_info["fixVersions"].join(',')
    
    jira_bug.save
    jira_bug
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
  def self.authenticate(username, password)
    @username = username
    @password = password
  end

  # Returns the URI for a given resource:
  # A resource can be 'issue', (just that for now)
  def self.make_jira_uri(resource)
    JIRA_BASE_URI + JIRA_RESOURCES[resource]
  end

  # Send a RESTful request to create a new issue in JIRA.
  # See the following docs for details:
  # https://docs.atlassian.com/jira/REST/latest/#idp1846544
  def self.create
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
  def self.update
    # Put parameters together.
    parameters = {
      # Stuff we're updating.
    }
    # Make JSON out of parameters.
    json = create_json_from_dict(parameters)

    # Put together URI of the form: 
    # http://hostname/rest/api/2/issue/{issueIdOrKey}
    uri = make_jira_uri(:issue) + params[:jira_issue_id]
    
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
  def self.get(issue_key)
    # Put together URI of the form: 
    # http://hostname/rest/api/2/issue/{issueIdOrKey}
    
    uri = URI.parse(JiraBug.make_jira_uri(:issue) + issue_key)
    
    request =  Net::HTTP::Get.new(uri.to_s, initheader = {'Content-Type' => 'application/json'})
    request.basic_auth @username, @password

    # Create HTTP request and get response
    $response = Net::HTTP.new(uri.host,uri.port)
    $response.use_ssl = true
    $response.verify_mode = OpenSSL::SSL::VERIFY_NONE
    $response = $response.start { |http| http.request(request) }
    # If you want to get the response code
    # response.code will give you that
    
    # Response Handler
    if $response.class == Net::HTTPOK
      # 200 returns json the "id", a "key", and a "self" (link to issue).
      dictionary = create_dict_from_json(JSON.parse($response.body))
    elsif $response.class == Net::HTTPNotFound
      # 404 for 'not found' or user doesn't 'have permission'
      nil
    end
  end

# Create a correctly formatted json object from a 
  # dictionary of parameters. This JSON must
  # adhere to the issue POST requirements:
  # https://docs.atlassian.com/jira/REST/latest/#idp1846544
  def self.create_json_from_dict(parameters)
    # 
    jira_map = {}
    fields_dict = {}
    

    # Do the fields
    JIRA_FIELDS.each do |k,v|
      # If field isn't in parameters, skip
      unless parameters.keys.include? k.to_s
        next
      end
      param = parameters[k.to_s]
      # Handle array types
      if v.is_a?(Array)
        fields_dict[k.to_s]=inject_list(param,v[0])
      elsif v.empty?
        fields_dict[k.to_s] = param
      else
        # Handle 'normal' fields
        fields_dict[k.to_s]={}
        fields_dict[k.to_s][v]=param
      end

    JIRA_INFO.each do |k|
      unless parameters.keys.include? k.to_s
        next
      end
      jira_map[k.to_s]=parameters[k.to_s]
    end

        
    end
    jira_map[:fields.to_s]=fields_dict
    jira_map
  end

 # Takes a jira style JSON and flattens it into
  # a regular dictionary.
  def self.create_dict_from_json(jira_json)
    d = {}

    # Grab the fields
    JIRA_FIELDS.each do |k,v|
      field = jira_json[:fields.to_s][k.to_s]

      
      # Only if it's not empty in json
      unless field.nil?
      if v.is_a?(Array)
          d[k.to_s] = extract_list(field, v[0])
          next
        end

        field_val = field[v]
        unless field_val.nil?
          # Handle lists of stuffs
          
          if v.empty?
            d[k.to_s] = field
          else
            d[k.to_s] = field_val
          end
        end
      end
    end

    # Grab the info
    JIRA_INFO.each do |k|
      info = jira_json[k.to_s].empty?
      unless info.nil?
        d[k.to_s]=jira_json[k.to_s]
      end
    end
    d # give the d
  end

  # Takes a list of hashes with lot's of
  # key value pairs, and returns a list of
  # just values from the wanted key
  def self.extract_list(items, key)
    items.map {|item| item[key]}
  end

  # Takes a list full of a bunch of values
  # and returns a list full of hashes with
  # the value assigned to a key
  def self.inject_list(list, key)
    list.map {|item| Hash[key,item]}
  end

end

