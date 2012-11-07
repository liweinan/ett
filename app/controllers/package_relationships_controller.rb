class PackageRelationshipsController < ApplicationController
  # GET /package_relationships
  # GET /package_relationships.xml
  def index
    @package_relationships = PackageRelationship.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @package_relationships }
    end
  end

  # GET /package_relationships/1
  # GET /package_relationships/1.xml
  def show
    @package_relationship = PackageRelationship.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @package_relationship }
    end
  end

  # GET /package_relationships/new
  # GET /package_relationships/new.xml
  def new
    @package_relationship = PackageRelationship.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @package_relationship }
    end
  end

  # GET /package_relationships/1/edit
  def edit
    @package_relationship = PackageRelationship.find(params[:id])
  end

  # POST /package_relationships
  # POST /package_relationships.xml
  def create
    @package_relationship = PackageRelationship.new(params[:package_relationship])

    respond_to do |format|
      if @package_relationship.save
        format.html { redirect_to(@package_relationship, :notice => 'PackageRelationship was successfully created.') }
        format.xml { render :xml => @package_relationship, :status => :created, :location => @package_relationship }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @package_relationship.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /package_relationships/1
  # PUT /package_relationships/1.xml
  def update
    @package_relationship = PackageRelationship.find(params[:id])

    respond_to do |format|
      if @package_relationship.update_attributes(params[:package_relationship])
        format.html { redirect_to(@package_relationship, :notice => 'PackageRelationship was successfully updated.') }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @package_relationship.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /package_relationships/1
  # DELETE /package_relationships/1.xml
  def destroy
    @package_relationship = PackageRelationship.find(params[:id])
    @package_relationship.destroy

    respond_to do |format|
      format.html { redirect_to(package_relationships_url) }
      format.xml { head :ok }
    end
  end
end
