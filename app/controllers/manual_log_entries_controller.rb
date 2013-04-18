class ManualLogEntriesController < ApplicationController
  # GET /manual_log_entries
  # GET /manual_log_entries.xml
  def index
    @manual_log_entries = ManualLogEntry.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @manual_log_entries }
    end
  end

  # GET /manual_log_entries/1
  # GET /manual_log_entries/1.xml
  def show
    @manual_log_entry = ManualLogEntry.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @manual_log_entry }
    end
  end

  # GET /manual_log_entries/new
  # GET /manual_log_entries/new.xml
  def new
    @manual_log_entry = ManualLogEntry.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @manual_log_entry }
    end
  end

  # GET /manual_log_entries/1/edit
  def edit
    @manual_log_entry = ManualLogEntry.find(params[:id])
  end

  # POST /manual_log_entries
  # POST /manual_log_entries.xml
  def create
    @manual_log_entry = ManualLogEntry.new(params[:manual_log_entry])

    respond_to do |format|
      if @manual_log_entry.save
        format.html { redirect_to(@manual_log_entry, :notice => 'ManualLogEntry was successfully created.') }
        format.xml  { render :xml => @manual_log_entry, :status => :created, :location => @manual_log_entry }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @manual_log_entry.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /manual_log_entries/1
  # PUT /manual_log_entries/1.xml
  def update
    @manual_log_entry = ManualLogEntry.find(params[:id])

    respond_to do |format|
      if @manual_log_entry.update_attributes(params[:manual_log_entry])
        format.html { redirect_to(@manual_log_entry, :notice => 'ManualLogEntry was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @manual_log_entry.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /manual_log_entries/1
  # DELETE /manual_log_entries/1.xml
  def destroy
    @manual_log_entry = ManualLogEntry.find(params[:id])
    @manual_log_entry.destroy

    respond_to do |format|
      format.html { redirect_to(manual_log_entries_url) }
      format.xml  { head :ok }
    end
  end
end
