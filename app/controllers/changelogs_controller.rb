class ChangelogsController < ApplicationController
  # GET /changelogs
  # GET /changelogs.xml
  def index
    @changelogs = Changelog.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @changelogs }
    end
  end

  # GET /changelogs/1
  # GET /changelogs/1.xml
  def show
    @changelog = Changelog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @changelog }
    end
  end

  # GET /changelogs/new
  # GET /changelogs/new.xml
  def new
    @changelog = Changelog.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @changelog }
    end
  end

  # GET /changelogs/1/edit
  def edit
    @changelog = Changelog.find(params[:id])
  end

  # POST /changelogs
  # POST /changelogs.xml
  def create
    @changelog = Changelog.new(params[:changelog])

    respond_to do |format|
      if @changelog.save
        format.html { redirect_to(@changelog, :notice => 'Changelog was successfully created.') }
        format.xml  { render :xml => @changelog, :status => :created, :location => @changelog }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @changelog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /changelogs/1
  # PUT /changelogs/1.xml
  def update
    @changelog = Changelog.find(params[:id])

    respond_to do |format|
      if @changelog.update_attributes(params[:changelog])
        format.html { redirect_to(@changelog, :notice => 'Changelog was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @changelog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /changelogs/1
  # DELETE /changelogs/1.xml
  def destroy
    @changelog = Changelog.find(params[:id])
    @changelog.destroy

    respond_to do |format|
      format.html { redirect_to(changelogs_url) }
      format.xml  { head :ok }
    end
  end
end
