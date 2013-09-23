class JiraBug < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "creator_id"
  belongs_to :package, :class_name => "Package", :foreign_key => "package_id"

  # http://hostname/rest/api/2/<resource-name>
  JIRA_BASE_URI = https://issues.jboss.org/rest/api/2
  JIRIA_AUTH_URI = https://issues.jboss.org/rest/auth
  JIRA_RESOURCES = {:issue => "issue"} # TODO: verify which JIRA resources are needed with huwang

  #JIRA_ACTIONS = {:movetoassigned => 'movetoassigned', :movetomodified => 'movetomodified', :accepted => 'accepted', :outofdate => 'outofdate', :done => 'done'}
  
  # Verify that these are all correct JIRA statuses:
  JIRA_STATUS = {:open => "Open", :resolved => "Resolved", :closed => "Closed", :in_progress => "In Progress", :reopened => "Reopened"}

  default_value_for :jira_status, 'NEW'
  default_value_for :jira_action, JIRA_ACTIONS[:done]
  default_value_for :last_synced_at, Time.now
  default_value_for :is_in_errata, "NO"



  # Create a new instance of a jira bug from the info passed to us from JIRA.
  def self.create_from_jira_info(jira_info, package_id, current_user)
    jiraBug = JiraBug.new
    jiraBug.package_id = package_id
    jiraBug.reporter = current_user.id
    jiraBug.type = jira_info["type"]
    jiraBug.priority = jira_info["priority"]
    jiraBug.components = jira_info["components"]
    # TODO: Insert all other necessary fields here once we verify what we need
    jiraBug.save
    jiraBug
  end

  # Update an existing JIRA bug with info from JIRA.
  def self.update_from_jira_info(jira_info, jira_issue_id)
    jiraBug.
    jiraBug.save
    jiraBug
  end

end

