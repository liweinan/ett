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
    result = ''

    ReadonlyTask.transaction do
      all_tasks = ReadonlyTask.all
      ReadonlyTask.all.each do |rt|
        rt.destroy
      end

      unless params[:task_ids].blank?
        params[:task_ids].each do |task_id|

          unless task_id_in_readonly_task(all_tasks, task_id)
            task = Task.find(task_id.to_i)
            result += "-------------------\n"
            result += "Packages moved to state 'Already Released':\n"
            result += ReadonlyTask.move_other_packages_to_already_released(task_id.to_i)
            result += "-------------------\n"
            task.active = nil
            task.frozen_state = "1"
            task.save
          end

          rt = ReadonlyTask.new
          rt.task_id = task_id.to_i
          rt.save
        end
      end
    end

    respond_to do |format|
      #if @readonly_task.update_attributes(params[:readonly_task])
      format.html do
        notice ='ReadonlyTask was successfully updated.'
        unless result.blank?
          notice += "\n" + result
        end
        redirect_to(readonly_tasks_path,
                    :notice => notice.gsub("\n", "<br/>"))
      end
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

  private
  def task_id_in_readonly_task(array_task, task_id)
    array_task.each do |task|
      return true if task.task_id == task_id.to_i
    end
    false # reach here if no task_id found
  end
end
