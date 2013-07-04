class StatusesController < ApplicationController
#  before_filter :check_product, :only => [:index]
  before_filter :check_can_manage, :only => [:new, :edit]

  # GET /statuses
  # GET /statuses.xml
  def index
    if params[:product_id].blank?
      @statuses = Status.all(:conditions => "global = 'Y'", :order => 'name')
    else
      @statuses = Status.all(:conditions => ["product_id = ?", Product.find_by_name(unescape_url(params[:product_id])).id], , :order => 'name')
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @statuses }
    end
  end

  # GET /statuses/1
  # GET /statuses/1.xml
  def show
    if params[:product_id].blank?
      @status = Status.find(:first, :conditions => ["global = 'Y' and name = ?", unescape_url(params[:id])])
    else
      @status = Status.find_by_name_and_product_id(unescape_url(params[:id]), Product.find_by_name(unescape_url(params[:product_id])).id)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @status }
    end
  end

  # GET /statuses/new
  # GET /statuses/new.xml
  def new
    @status = Status.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @status }
    end
  end

  # GET /statuses/1/edit
  def edit
    if params[:product_id].blank?
      @status = Status.find(:first, :conditions => ["name = ? AND global='Y'", unescape_url(params[:id])])
    else
      @status = Status.find_by_name_and_product_id(unescape_url(params[:id]), Product.find_by_name(unescape_url(params[:product_id])).id)
    end
  end

  # POST /statuses
  # POST /statuses.xml
  def create
    expire_all_fragments
    @status = Status.new(params[:status])

    respond_to do |format|
      if @status.save
        flash[:notice] = 'Status was successfully created.'
        format.html {
          if is_global?(@status)
            redirect_to :controller => :statuses, :action => :show, :id => escape_url(@status.name)
          else
            redirect_to :controller => :statuses, :action => :show, :id => escape_url(@status.name), :product_id => escape_url(@status.product.name)
          end

        }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /statuses/1
  # PUT /statuses/1.xml
  def update
    expire_all_fragments
    @status = Status.find(params[:status][:id])

    respond_to do |format|
      if @status.update_attributes(params[:status])
        flash[:notice] = 'Status was successfully updated.'
        format.html {
          unless is_global?(@status)
            redirect_to :controller => :statuses, :action => :show, :id => escape_url(@status.name), :product_id => escape_url(@status.product.name)
          else
            redirect_to :controller => :statuses, :action => :show, :id => escape_url(@status.name)
          end
        }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /statuses/1
  # DELETE /statuses/1.xml
  def destroy
    @status = Status.find(params[:id])
    @status.destroy

    respond_to do |format|
      format.html { redirect_to(statuses_url) }
      format.xml { head :ok }
    end
  end

end
