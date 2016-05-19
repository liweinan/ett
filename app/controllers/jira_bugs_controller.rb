require 'jira_bug.rb'

class JiraBugsController < ApplicationController

  def create
    jira_name = params[:jira_value].strip
    pkg = Package.find(params[:package_id])
    jira_server = APP_CONFIG['jira_server']

    rest_url = URI.parse("#{jira_server}/rest/api/2/issue/#{jira_name}")
    http = Net::HTTP.new(rest_url.host, rest_url.port)
    http.use_ssl = true
    res = http.request(Net::HTTP::Get.new(rest_url.request_uri))

    res_json = JSON.parse(res.body)
    if res_json['fields'].key?('assignee') && res_json['fields']['assignee'].key?('displayName')
      assignee_name = res_json['fields']['assignee']['displayName']
    else
      assignee_name = ''
    end
    summary = res_json['fields']['summary']
    status = res_json["fields"]["status"]["statusCategory"]["name"]

    @jira_bug = JiraBug.new
    @jira_bug.assignee = assignee_name
    @jira_bug.summary = summary
    @jira_bug.status = status
    @jira_bug.package_id = pkg.id
    @jira_bug.jira_bug = jira_name
    @jira_bug.creator_id = current_user.id
    @jira_bug.last_synced_at = Time.now
    @jira_bug.save

    respond_to do |format|
      format.js { render :status => 200 }
    end
  end

  def destroy
    JiraBug.find(params[:id]).destroy
  end

  def render_partial
    if params[:package_id] != '0'
      @package = Package.find(params[:package_id])
    end
    respond_to do |format|

      format.js do
        if params[:id].scan(/\d+/) != ['0']
          jira_bug_temp = JiraBug.find(params[:id].scan(/\d+/))[0]
        else
          jira_bug_temp = nil
        end
        render(:partial => params[:partial],
               :locals => {:id => params[:id],
                           :package_id => params[:package_id],
                           :jira_bug => jira_bug_temp})
      end
    end
  end
end
