class LabelsController < ApplicationController
#  before_filter :check_product, :only => [:index]
  before_filter :check_can_manage, :only => [:new, :edit]

  # GET /labels
  # GET /labels.xml
  def index
    if params[:product_id].blank?
      @labels = Label.all(:conditions => "global = 'Y'")
    else
      @labels = Label.all(:conditions => ["product_id = ?", Product.find_by_name(unescape_url(params[:product_id])).id])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @labels }
    end
  end

  # GET /labels/1
  # GET /labels/1.xml
  def show
    if params[:product_id].blank?
      @label = Label.find(:first, :conditions => ["global = 'Y' and name = ?", unescape_url(params[:id])])
    else
      @label = Label.find_by_name_and_product_id(unescape_url(params[:id]), Product.find_by_name(unescape_url(params[:product_id])).id)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @label }
    end
  end

  # GET /labels/new
  # GET /labels/new.xml
  def new
    @label = Label.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @label }
    end
  end

  # GET /labels/1/edit
  def edit
    if params[:product_id].blank?
      @label = Label.find(:first, :conditions => ["name = ? AND global='Y'", unescape_url(params[:id])])
    else
      @label = Label.find_by_name_and_product_id(unescape_url(params[:id]), Product.find_by_name(unescape_url(params[:product_id])).id)
    end
  end

  # POST /labels
  # POST /labels.xml
  def create
    expire_all_fragments
    @label = Label.new(params[:label])

    respond_to do |format|
      if @label.save
        flash[:notice] = 'Label was successfully created.'
        format.html {
          if is_global?(@label)
            redirect_to :controller => :labels, :action => :show, :id => escape_url(@label.name)
          else
            redirect_to :controller => :labels, :action => :show, :id => escape_url(@label.name), :product_id => escape_url(@label.product.name)
          end

        }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /labels/1
  # PUT /labels/1.xml
  def update
    expire_all_fragments
    @label = Label.find(params[:label][:id])

    respond_to do |format|
      if @label.update_attributes(params[:label])
        flash[:notice] = 'Label was successfully updated.'
        format.html {
          unless is_global?(@label)
            redirect_to :controller => :labels, :action => :show, :id => escape_url(@label.name), :product_id => escape_url(@label.product.name)
          else
            redirect_to :controller => :labels, :action => :show, :id => escape_url(@label.name)
          end
        }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /labels/1
  # DELETE /labels/1.xml
  def destroy
    @label = Label.find(params[:id])
    @label.destroy

    respond_to do |format|
      format.html { redirect_to(labels_url) }
      format.xml { head :ok }
    end
  end

end
