require 'jira_bug.rb'

class JiraBugsController < ApplicationController
  # GET /jira_bugs
  def index
    @jira_bugs = JiraBug.all
  end

  def show
    JiraBug.authenticate(@username, @password)

    begin
      # The bug:
      @jira_bug = JiraBug.find(params[:id])
      # Grab the issue info from JIRA
      @info = JiraBug.get(params[:id])
    rescue => e
      # Handle errors here
      raise
    end
  end

  def create
  end

  def edit
  end

  def update
    JiraBug.authenticate(@username,@password)

    # Do stuff in here

  end

  def destroy
  end

  def sync
    # Authenticate from userinfo
    JiraBug.authenticate(@username,@password)

    begin
    # Grab the issue info from JIRA
    @info = JiraBug.get(params[:id])

      # Is it already in database?
      if JiraBug.exists?(:key => params[:id]) then
        # Update the local copy
        @jira_bug = JiraBug.find(params[:id])
        JiraBug.update_from_jira_info(@info, @jira_bug)
      else
        # Create a new local copy
        @jira_bug = JiraBug.create_from_jira_info(@info)
      end
  
    rescue => e
      # Handle errors here
      raise
    end

  end
 
end
