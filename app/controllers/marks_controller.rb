class MarksController < ApplicationController
  before_filter :check_tag, :only => [:index, :new]
  before_filter :check_can_manage, :only => [:new, :edit]

  # GET /attributes
  # GET /attributes.xml
  def index
    @marks = Mark.all(:conditions => ["product_id = ?", get_product(params[:product_id]).id])

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @marks }
    end
  end

  # GET /attributes/1
  # GET /attributes/1.xml
  def show
    @mark = Mark.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @mark }
    end
  end

  # GET /attributes/new
  # GET /attributes/new.xml
  def new
    @mark = Mark.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @mark }
    end
  end

  # GET /attributes/1/edit
  def edit
    @mark = Mark.find(params[:id])
  end

  # POST /attributes
  # POST /attributes.xml
  def create
    expire_all_fragments
    @mark = Mark.new(params[:mark])

    respond_to do |format|
      if @mark.save
        flash[:notice] = 'Mark was successfully created.'
        format.html { redirect_to(:action => :show, :id => @mark.id, :product_id => escape_url(@mark.product.name)) }
      else
        format.html { render :action => :new }
      end
    end
  end

  # PUT /attributes/1
  # PUT /attributes/1.xml
  def update
    expire_all_fragments
    @mark = Mark.find(params[:id])

    respond_to do |format|
      if @mark.update_attributes(params[:mark])
        flash[:notice] = 'Mark was successfully updated.'
        format.html { redirect_to(:action => :show, :id => @mark.id, :product_id => @mark.product.name) }
      else
        format.html { render :action => :edit }
      end
    end
  end

  # DELETE /attributes/1
  # DELETE /attributes/1.xml
  def destroy
    @mark = Mark.find(params[:id])
    @mark.destroy

    respond_to do |format|
      format.html { redirect_to(attributes_url) }
      format.xml { head :ok }
    end
  end
end
