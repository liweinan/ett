class WorkflowsController < ApplicationController
  # GET /workflows
  # GET /workflows.xml
  def index
    @workflows = Workflow.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @workflows }
    end
  end

  # GET /workflows/1
  # GET /workflows/1.xml
  def show
    @workflow = Workflow.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @workflow }
    end
  end

  # GET /workflows/new
  # GET /workflows/new.xml
  def new
    @workflow = Workflow.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @workflow }
    end
  end

  # GET /workflows/1/edit
  def edit
    @workflow = Workflow.find(params[:id])
  end

  # POST /workflows
  # POST /workflows.xml
  def create
    @workflow = Workflow.new(params[:workflow])
    # In WildBee we should save workflow and allowedStatus in one transaction.
    # Currently we have to save workflow to get its primary key
    if @workflow.save # just to get primary id.
      Workflow.transaction do
        update_workflow
      end
      respond_to do |format|
        format.html do
          redirect_to(@workflow,
                      :notice => 'Workflow was successfully created.')
        end
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end


  # PUT /workflows/1
  # PUT /workflows/1.xml
  def update
    @workflow = Workflow.find(params[:id])

    respond_to do |format|
      Workflow.transaction do
        if @workflow.update_attributes(params[:workflow])
          update_workflow

          format.html do
            redirect_to(@workflow,
                        :notice => 'Workflow was successfully updated.')
          end
        else
          format.html { render :action => 'edit' }
        end
      end
    end
  end

  def update_workflow
    @workflow.update_transitions(params[:transitions])
    @workflow.update_start_statuses(params[:start_statuses_id])
    @workflow.assign_to_tasks(params[:tasks])
  end

  # DELETE /workflows/1
  # DELETE /workflows/1.xml
  def destroy
    @workflow = Workflow.find(params[:id])
    @workflow.destroy

    respond_to do |format|
      format.html { redirect_to(workflows_url) }
      format.xml { head :ok }
    end
  end

  protected
end
