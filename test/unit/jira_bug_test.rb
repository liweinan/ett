#require 'test_helper'
require 'rubygems'
require 'net/http'
require 'json'

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

# Create a correctly formatted json object from a 
  # dictionary of parameters. This JSON must
  # adhere to the issue POST requirements:
  # https://docs.atlassian.com/jira/REST/latest/#idp1846544
  def create_json_from_dict(parameters)
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
  def create_dict_from_json(jira_json)
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
  def extract_list(items, key)
  	items.map {|item| item[key]}
  end

  # Takes a list full of a bunch of values
  # and returns a list full of hashes with
  # the value assigned to a key
  def inject_list(list, key)
  	list.map {|item| Hash[key,item]}
  end

#class JiraBugTest < ActiveSupport::TestCase
  # Replace this with your real tests.
	paramtest = {
	  "key" => "JBEAP-234",
	  "self" => "http://google.com",
	  "id" => "234",
	  "project" => "myding", 
	  "summary" => "just trying some stuff",
	  "assignee" => "me", 
	  "monkeys" => "orangutan",
	  "priority"=>"daaaaan!",
	  "reporter"=>"hoser",
	  "versions"=>["eap5.1","eap5.2"],
	  "fixVersions"=>["eap5.1"]
	}
	# puts "This is a flat dict containing JIRA info:"
	# puts JSON.pretty_generate(paramtest)

	puts "Making JSON from Dict:"
	j=create_json_from_dict(paramtest)
	puts JSON.pretty_generate(j)

	 puts "adding fluff to json"
	 j["sandwiche"]="mo' sandwich"
	 puts JSON.pretty_generate(j)	

	 puts "Making Dict from JSON:"
	 d=create_dict_from_json(j)
	 puts JSON.pretty_generate(d)

	puts "Grabbing jb.json"
  	jb = JSON.parse( IO.read("./helper_objects/jb.json") )
  	#puts JSON.pretty_generate(jb)

	puts jb["id"]
  	puts "Flattening jb.json"
  	puts JSON.pretty_generate(create_dict_from_json(jb))

#end
