class ReadonlyTasksController < ApplicationController
  # GET /readonly_tasks
  # GET /readonly_tasks.xml
  def index
    @readonly_tasks = ReadonlyTask.all(:order => :task_id)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /readonly_tasks/1
  # GET /readonly_tasks/1.xml
  def show
    @readonly_task = ReadonlyTask.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @readonly_task }
    end
  end

  # GET /readonly_tasks/1/edit
  def edit
    @readonly_task = ReadonlyTask.new
    @readonly_task.id = 0
  end

  # PUT /readonly_tasks/1
  # PUT /readonly_tasks/1.xml
  def update
    #@readonly_task = ReadonlyTask.find(params[:id])
    ReadonlyTask.transaction do
      ReadonlyTask.all.each do |rt|
        rt.destroy
      end

      unless params[:task_ids].blank?
        params[:task_ids].each do |task_id|
          rt = ReadonlyTask.new
          rt.task_id = task_id.to_i
          rt.save
        end
      end
    end

    respond_to do |format|
      #if @readonly_task.update_attributes(params[:readonly_task])
      format.html { redirect_to(readonly_tasks_path, :notice => 'ReadonlyTask was successfully updated.') }
      #  format.xml  { head :ok }
      #else
      #  format.html { render :action => "edit" }
      #  format.xml  { render :xml => @readonly_task.errors, :status => :unprocessable_entity }
      #end
    end
  end

  # DELETE /readonly_tasks/1
  # DELETE /readonly_tasks/1.xml
  def destroy
    @readonly_task = ReadonlyTask.find(params[:id])
    @readonly_task.destroy

    respond_to do |format|
      format.html { redirect_to(readonly_tasks_url) }
      format.xml { head :ok }
    end
  end
end
