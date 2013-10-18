require 'jira_bug.rb'

class JiraBugsController < ApplicationController
  # GET /jira_bugs
  def index
    @jira_bugs = JiraBug.all
  end

  def show
    @jira_bug = JiraBug.find(params[:id])
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end

  def sync
    JiraBug.authenticate("fcanas","trisveryfuzzy")
    jira_info = JiraBug.get(params[:id])
    
    unless jira_info.blank?
      if JiraBug.exists?(:id => params[:id]) then
        @jira_bug = JiraBug.find(params[:id])
        @jira_bug.update_from_jira_info(jira_info, params[:id])
      else
        @jira_bug = JiraBug.create_from_jira_info(jira_info,params[:package_id].strip, current_user)
      end
    end

  end
end
