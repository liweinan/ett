class SettingsController < ApplicationController
  before_filter :check_can_manage, :only => [:index, :new, :edit]
  before_filter :triage, :only => [:index]
  # GET /settings
  # GET /settings.xml
  def index
    @settings = Setting.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @settings }
    end
  end

  # GET /settings/1
  # GET /settings/1.xml
  def show
    if params[:id] == '-1'
      task = Task.find_by_name(unescape_url(params[:task_id]))
      @setting = Setting.find_by_task_id(task.id)
      if @setting.blank?
        @setting = Setting.new
        @setting.task = task
        @setting.save
      end
    else
      @setting = Setting.find(params[:id])
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @setting }
    end
  end

  # GET /settings/new
  # GET /settings/new.xml
  def new
    @setting = Setting.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @setting }
    end
  end

  # GET /settings/1/edit
  def edit
    @setting = Setting.find(params[:id])
  end

  # POST /settings
  # POST /settings.xml
  def create
    @setting = Setting.new(params[:setting])

    respond_to do |format|
      if @setting.save

        format.html do
          redirect_to(@setting,
                      :notice => 'Setting was successfully created.')
        end

        format.xml { render :xml => @setting, :status => :created, :location => @setting }

      else
        format.html { render :action => 'new' }
        format.xml { render :xml => @setting.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /settings/1
  # PUT /settings/1.xml
  def update
    expire_all_fragments

    @setting = Setting.find(params[:id])
    params[:setting][:props] = array_to_flag(params[:props])
    params[:setting][:actions] = array_to_flag(params[:actions])

    unless params[:setting][:show_xattrs] == 'Yes'
      params[:setting][:show_xattrs] = 'No'
    end

    unless params[:setting][:enable_xattrs] == 'Yes'
      params[:setting][:enable_xattrs] = 'No'
    end

    unless params[:setting][:enabled] == 'Yes'
      params[:setting][:enabled] = 'No'
    end

    respond_to do |format|
      if @setting.update_attributes(params[:setting])

        format.html { redirect_to(@setting, :notice => 'Setting was successfully updated.') }
        format.xml { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml { render :xml => @setting.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /settings/1
  # DELETE /settings/1.xml
  def destroy
    @setting = Setting.find(params[:id])
    @setting.destroy

    respond_to do |format|
      format.html { redirect_to(settings_url) }
      format.xml { head :ok }
    end
  end

  protected

  def triage
    #if params[:id].blank? && params[:task_id].blank?
      redirect_to(:action => :show, :id => Setting.system_settings.id)
    #end
  end

  def array_to_flag(array)
    flag = 0
    if array && array.class == Array
      array.each do |v|
        flag |= v.to_i
      end
    end
    flag
  end
end
