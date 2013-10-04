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
    :versions => "id", 
    :fixVersions => "id", 
    :environment => "", 
    :description => ""}

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
    jira_map[:fields]={}

    # All the fields get put into "fields"
    parameters.each do |p, v|
      # If it's in "fields"
      if JIRA_FIELDS.key?(p)
        if JIRA_FIELDS[p].empty?
          jira_map[:fields][p]=v
        else
          jira_map[:fields][p]={}
          jira_map[:fields][p][JIRA_FIELDS[p]]=v
        end
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
          # Skip it if not in our fields list.
          if not JIRA_FIELDS.include? f
            next
          end
          if JIRA_FIELDS[f].empty?
            d[f]=v[f]
          else
            d[f]=i[JIRA_FIELDS[f]]
        end
        end
      # Handle others
      else 
        # Keep it if it's in the info list.
        if JIRA_INFO.include? k
          d[k]=v
        end
      end
    end
    d
  end

#class JiraBugTest < ActiveSupport::TestCase
  # Replace this with your real tests.
	paramtest = {
	  :key => "JBEAP-234",
	  :self => "http://google.com",
	  :id => "234",
	  :project => "myding", 
	  :summary => "just trying some stuff",
	  :assignee => "me", 
	  :monkeys => "orangutan",
	  :priority=>"daaaaan!",
	  :reporter=>"hoser"
	}
	puts "This is a flat dict containing JIRA info:"
	puts JSON.pretty_generate(paramtest)

	puts "Making JSON from Dict:"
	j=create_json_from_dict(paramtest)
	puts JSON.pretty_generate(j)

	puts "adding fluff to json"
	j["sandwiche"]="mo' sandwich"
	puts JSON.pretty_generate(j)	

	puts "Making Dict from JSON:"
	d=create_dict_from_json(j)
	puts JSON.pretty_generate(d)
#end
