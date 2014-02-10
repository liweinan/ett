class ComponentsController < ApplicationController
  before_filter :check_can_manage, :only => [:edit, :new]

  def index
  end

  def new
    @component = Component.new
  end

  def edit
    @component = Component.find_by_name(unescape_url(params[:id]))
    @task_names = []
    @component.tasks.each do |task|
      @task_names << task.name
    end
  end

  def create
    expire_all_fragments
    @component = Component.new(params[:component])
    @component.tasks = collect_tasks(params[:task_names])

    respond_to do |format|
      if @component.save
        format.html do
          redirect_to(:action => :show,
                      :id => escape_url(@component.name),
                      :notice => 'Component was successfully created.')
        end
      else
        format.html { render :action => 'new' }
      end
    end
  end

  def update
    expire_all_fragments
    @component = Component.find(params[:id])
    respond_to do |format|
      if @component.update_attributes(params[:component])
        @component.tasks = collect_tasks(params[:task_names])
        @component.save

        flash[:notice] = 'Component was successfully updated.'
        format.html { render :action => 'updated' }
      else
        format.html { render :action => 'edit' }
      end
    end

  end

  def destroy
    @component = Component.find(params[:id])
    @component.destroy

    respond_to do |format|
      format.html { redirect_to(components_url) }
    end
  end


  def show
    @component = Component.find_by_name(unescape_url(params[:id]))
    if @component.blank?
      redirect_to(:action => :index)
    else
      @packages = Package.distinct_in_tasks_can_show(@component.tasks)
    end

  end

  protected

  def collect_tasks(task_names)
    unless task_names.blank?
      tasks = []
      task_names.each do |task_name|
        tasks << Task.find_by_name(task_name)
      end
      return tasks
    end
    []
  end

end
