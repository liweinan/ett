class TagsController < ApplicationController
  before_filter :check_product, :only => [:index, :new]
  before_filter :check_can_manage, :only => [:new, :edit]

  # GET /attributes
  # GET /attributes.xml
  def index
    @tags = Tag.all(:conditions => ["product_id = ?", get_product(params[:product_id]).id])

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @tags }
    end
  end

  # GET /attributes/1
  # GET /attributes/1.xml
  def show
    @tag = Tag.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @tag }
    end
  end

  # GET /attributes/new
  # GET /attributes/new.xml
  def new
    @tag = Tag.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @tag }
    end
  end

  # GET /attributes/1/edit
  def edit
    @tag = Tag.find(params[:id])
  end

  # POST /attributes
  # POST /attributes.xml
  def create
    expire_all_fragments
    @tag = Tag.new(params[:tag])

    respond_to do |format|
      if @tag.save
        flash[:notice] = 'Tag was successfully created.'
        format.html { redirect_to(:action => :show, :id => @tag.id, :product_id => escape_url(@tag.product.name)) }
      else
        format.html { render :action => :new }
      end
    end
  end

  # PUT /attributes/1
  # PUT /attributes/1.xml
  def update
    expire_all_fragments
    @tag = Tag.find(params[:id])

    respond_to do |format|
      if @tag.update_attributes(params[:tag])
        flash[:notice] = 'Tag was successfully updated.'
        format.html { redirect_to(:action => :show, :id => @tag.id, :product_id => @tag.product.name) }
      else
        format.html { render :action => :edit }
      end
    end
  end

  # DELETE /attributes/1
  # DELETE /attributes/1.xml
  def destroy
    @tag = Tag.find(params[:id])
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to(attributes_url) }
      format.xml { head :ok }
    end
  end
end
