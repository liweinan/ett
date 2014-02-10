require 'jira_bug.rb'

class JiraBugsController < ApplicationController
  # GET /jira_bugs
  def index
    @jira_bugs = JiraBug.all
  end

  def show 
    begin
        # Is it already in database?
      if JiraBug.exists?(:key => params[:id])
        # Update the local copy
        puts "#{params[:id]} found."
        @jira_bug = JiraBug.find(params[:id])
      else
        puts "#{params[:id]} not found."
      end
    rescue => e
      # Handle errors here
      raise
    end
  end

  def new
  end

  def create
  end

  # This update action should be called when the user 
  # hits the 'submit' button on an edit issue form.
  # The params are all of the fields being edited
  # and the other fields for the bug.
  def update
    begin_check_param
    check_param_user(params)
    check_param_pwd(params)
    end_check_param
    
    # Authenticate from userinfo
    JiraBug.authenticate(params[:jira_user], params[:jira_pass])
    
    @response = JiraBug.update(params)

    @jira_bug = JiraBug.find(params[:id])
    @info = JiraBug.get(params[:id])
    # Update the local copy of the JIRA as well
    JiraBug.update_from_jira_info(@info, @jira_bug)
  end

  def edit
      if JiraBug.exists?(:key => params[:id])
        # Update the local copy
        @jira_bug = JiraBug.find(params[:id])
      else
        @jira_bug = nil
      end
  end

  def destroy
  end

  def sync
      begin_check_param
      check_param_user(params)
      check_param_pwd(params)
      end_check_param
    # Authenticate from userinfo
    JiraBug.authenticate(params[:jira_user], params[:jira_pass])
    
    begin
    # Grab the issue info from JIRA
    @info = JiraBug.get(params[:id])

    if @info.nil?
      # handle 
      raise ArgumentError, 'Jira did not find an issue by that key.'
    end

      # Is it already in database?
      if JiraBug.exists?(:key => params[:id])
        # Update the local copy
        @jira_bug = JiraBug.find(params[:id])

        unless @jira_bug.nil?
          JiraBug.update_from_jira_info(@info, @jira_bug)
        else
          raise
        end
      else
        # Create a new local copy
        @jira_bug = JiraBug.create_from_jira_info(@info)
      end
  
    rescue => e
      # Handle errors here
      raise e
    end

  end

  def check_param_user(params)
    if params[:jira_user].blank?
      @err_msg << "Jira account user can't be empty.\n"
    end
  end

  def check_param_pwd(params)
    if params[:jira_pass].blank?
      @err_msg << "Jira account password can't be empty.\n"
    end
  end

  def begin_check_param
    @err_msg = ''
  end

  def end_check_param
    unless @err_msg.blank?
      raise ArgumentError, @err_msg
    end
  end
 
end
