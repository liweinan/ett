class TasksController < ApplicationController
  before_filter :check_can_manage, :only => [:create, :update, :new, :edit, :clone, :clone_review]
  before_filter :clone_form_validation, :only => :clone

  # GET /tasks
  # GET /tasks.xml
  def index
    @tasks = Task.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @tasks }
    end
  end

  # GET /tasks/1
  # GET /tasks/1.xml
  def show
    @task = Task.find_by_name(unescape_url(params[:id]))

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @task }
    end
  end

  # GET /tasks/new
  # GET /tasks/new.xml
  def new
    if can_manage?
      @task = Task.new
    end

    respond_to do |format|
      format.html {
        unless can_manage?
          redirect_to('/')
        end
      }
      format.xml { render :xml => @task }
    end
  end

  # GET /tasks/1/edit
  def edit
    if can_manage?
      @task = Task.find_by_name(unescape_url(params[:id]))
    else
      redirect_to('/')
    end
  end

  # POST /tasks
  # POST /tasks.xml
  def create
    if can_manage?
      @task = Task.new(params[:task])
      params[:task][:name].strip!
      params[:task][:name].downcase!
    end

    respond_to do |format|
      if can_manage?
        if @task.save
          expire_all_fragments
          flash[:notice] = 'Task was successfully created.'
          format.html { redirect_to(:controller => :tasks, :action => :show, :id => escape_url(@task.name)) }
        else
          format.html {
            render :action => "new"
          }
        end
      else
        format.html { redirect_to('/') }
      end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.xml
  def update
    @task = Task.find(params[:id])
    params[:task][:name].strip!
    params[:task][:name].downcase!

    os_adv_tags = params.keys.select {|key| key.to_s.start_with? "task_os"}
    os_adv_tags = os_adv_tags.sort_by &:to_s

    # verify if all the fields are filled

    os_adv_tag_error = false
    modify_any_os_adv_tag = verify_os_options_valid(os_adv_tags, params)

    # if only the first field is filled and they are left blank, ignore
    os_adv_tag_error = true if (os_adv_tags.size != 1 && !modify_any_os_adv_tag)

    if !os_adv_tag_error && modify_any_os_adv_tag
      update_and_add_new_os_adv_tag(os_adv_tags, params, @task)
    end

    respond_to do |format|
      if @task.update_attributes(params[:task]) && !os_adv_tag_error
        expire_all_fragments
        flash[:notice] = 'Task was successfully updated.'
        format.html { redirect_to(:controller => :tasks, :action => :show, :id => escape_url(@task.name)) }
        format.xml { head :ok }
      else
        if os_adv_tag_error
          flash[:notice] = "You cannot leave Os, Advisory and Candidate tag blank"
        end
        format.html { render :action => "edit" }
        format.xml { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.xml
  def destroy
    @task = Task.find(params[:id])
    @task.destroy

    Task.find_by_name(unescape_url(params[:id]))
    respond_to do |format|
      format.html { redirect_to(tasks_url) }
      format.xml { head :ok }
    end
  end

  def clone
    if request.post?
      session[:clone_review] = Hash.new
      unless params[:source_task_name].blank?
        session[:clone_review][:source_task_name] = params[:source_task_name].strip
      end

      unless params[:target_task_name].blank?
        session[:clone_review][:target_task_name] = params[:target_task_name].strip
      end

      session[:clone_review][:scopes] = params[:scopes]
      session[:clone_review][:tag_options] = params[:tag_options]
      session[:clone_review][:tag_options] ||= []
      session[:clone_review][:status_option] = params[:status_option]
      session[:clone_review][:initial_tag_values] = params[:initial_tag_values]
      session[:clone_review][:tags] = params[:tags]
      session[:clone_review][:initial_status_value] = params[:initial_status_value]
      session[:clone_review][:status_selection_value] = params[:status_selection_value]
      session[:clone_review][:status_selection_value_global] = params[:status_selection_value_global]
      session[:clone_review][:task] = params[:task]

      redirect_to :action => :clone_review, :id => escape_url(params[:source_task_name])
    else
      @task = Task.find_by_name(unescape_url(params[:id]))
    end
  end

  def clone_review

  end

  def process_clone
    task_clone_in_progress
  end

  def render_partial
    respond_to do |format|
      format.js {
        render(:partial => params[:partial], :locals => {:count => params[:count]})
      }
    end
  end



  protected

  def clone_form_validation
    unless request.post?
      return
    end

    @error_message = []

    if params[:source_task_name].blank?
      @error_message << "Source task name not specified."
    end

    if params[:target_task_name].blank?
      @error_message << "Target task name not specified."
    #else
    #  @task = Task.find_by_name(unescape_url(params[:target_task_name].downcase.strip))
    #  if @task
    #    @error_message << "Target task name already used."
    #  end
    end

    if params[:source_task_name].strip == params[:target_task_name].strip
      @error_message << "task cannot be cloned to itself."
    end

    if params[:scopes].blank?
      @error_message << "Nothing set to clone."
    else
      if params[:scopes].include? 'package'
        if params[:status_option] == 'new_value'
          if params[:initial_status_value].blank?
            @error_message << "Initial status not set."
          elsif Status.find_in_global_scope(params[:initial_status_value].downcase.strip, unescape_url(params[:target_task_name]).downcase.strip)
            @error_message << "Initial status name already used."

          end
        end

        if !params[:tag_options].blank? && params[:tag_options].include?('new_value')
          if params[:initial_tag_values].blank?
            @error_message << "Initial tags not set."
          end
        end
      end
    end

    unless @error_message.blank?
      @task = Task.find_by_name(unescape_url(params[:source_task_name]))
      render :controller =>'tasks', :action => 'clone', :id => escape_url(params[:source_task_name])
    end
  end

  def verify_os_options_valid(os_adv_tags, params)

    params_os = "task_os_"
    params_adv = "task_advisory_"
    params_tag = "task_tag_"

    num_os_adv_tags = os_adv_tags.size
    (1..num_os_adv_tags).each do |i|
      if params[params_os + i.to_s].blank? ||
         params[params_adv + i.to_s].blank? ||
         params[params_tag + i.to_s].blank?
        return false
      end
    end
    # if everything valid
    return true
  end

  # TODO: optimize this. right now I'm just dumbly deleting and recreating new
  # ones
  def update_and_add_new_os_adv_tag(os_adv_tags, params, task)

    params_os = "task_os_"
    params_adv = "task_advisory_"
    params_tag = "task_tag_"

    # delete existing ones
    task.os_advisory_tags.each {|to_delete| to_delete.delete}

    os_adv_tags.each_with_index do |to_insert, x|
      i = x + 1
      to_save = OsAdvisoryTag.new
      to_save.os_arch = params[params_os + i.to_s]
      to_save.advisory = params[params_adv + i.to_s]
      to_save.candidate_tag = params[params_tag + i.to_s]
      to_save.task_id = task.id
      to_save.priority = i.to_s
      to_save.save
    end
  end
end
