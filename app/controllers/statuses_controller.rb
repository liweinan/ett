class StatusesController < ApplicationController
#  before_filter :check_task, :only => [:index]
  before_filter :check_can_manage, :only => [:new, :edit]

  # GET /statuses
  # GET /statuses.xml
  def index
    if params[:task_id].blank?
      @statuses = Status.all(:conditions => "global = 'Y'", :order => 'name')
    else
      @statuses = Status.all(:conditions => ['task_id = ?',
                                             Task.find_by_name(unescape_url(params[:task_id])).id],
                             :order => 'name')
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @statuses }
    end
  end

  # GET /statuses/1
  # GET /statuses/1.xml
  def show
    if params[:task_id].blank?
      @status = Status.find(:first,
                            :conditions => ["global = 'Y' and name = ?",
                                            unescape_url(params[:id])])
    else
      @status = Status.find_by_name_and_task_id(unescape_url(params[:id]),
                                                Task.find_by_name(unescape_url(params[:task_id])).id)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @status }
    end
  end

  # GET /statuses/new
  # GET /statuses/new.xml
  def new
    @status = Status.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @status }
    end
  end

  # GET /statuses/1/edit
  def edit
    if params[:task_id].blank?
      @status = Status.find(:first,
                            :conditions => ["name = ? AND global='Y'",
                                            unescape_url(params[:id])])
    else
      @status = Status.find_by_name_and_task_id(unescape_url(params[:id]),
                                                Task.find_by_name(unescape_url(params[:task_id])).id)
    end
  end

  # POST /statuses
  # POST /statuses.xml
  def create
    expire_all_fragments
    @status = Status.new(params[:status])

    respond_to do |format|
      if @status.save
        flash[:notice] = 'Status was successfully created.'
        format.html {
          if is_global?(@status)
            redirect_to :controller => :statuses,
                        :action => :show,
                        :id => escape_url(@status.name)
          else
            redirect_to :controller => :statuses,
                        :action => :show,
                        :id => escape_url(@status.name),
                        :task_id => escape_url(@status.task.name)
          end

        }
      else
        format.html { render :action => 'new' }
      end
    end
  end

  # PUT /statuses/1
  # PUT /statuses/1.xml
  def update
    expire_all_fragments
    @status = Status.find(params[:status][:id])

    respond_to do |format|
      if @status.update_attributes(params[:status])
        flash[:notice] = 'Status was successfully updated.'
        format.html do
          if is_global?(@status)
            redirect_to :controller => :statuses,
                        :action => :show,
                        :id => escape_url(@status.name)
          else
            redirect_to :controller => :statuses,
                        :action => :show,
                        :id => escape_url(@status.name),
                        :task_id => escape_url(@status.task.name)
          end
        end
      else
        format.html { render :action => 'edit' }
      end
    end
  end

  # DELETE /statuses/1
  # DELETE /statuses/1.xml
  def destroy
    @status = Status.find(params[:id])
    @status.destroy

    respond_to do |format|
      format.html { redirect_to(statuses_url) }
      format.xml { head :ok }
    end
  end

end
