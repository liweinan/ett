class ProductsController < ApplicationController
  before_filter :check_can_manage, :only => [:create, :update, :new, :edit, :clone, :clone_review]
  before_filter :clone_form_validation, :only => :clone

  # GET /products
  # GET /products.xml
  def index
    @products = Product.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @products }
    end
  end

  # GET /products/1
  # GET /products/1.xml
  def show
    @product = Product.find_by_name(unescape_url(params[:id]))

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @product }
    end
  end

  # GET /products/new
  # GET /products/new.xml
  def new
    if can_manage?
      @product = Product.new
    end

    respond_to do |format|
      format.html {
        unless can_manage?
          redirect_to('/')
        end
      }
      format.xml { render :xml => @product }
    end
  end

  # GET /products/1/edit
  def edit
    if can_manage?
      @product = Product.find_by_name(unescape_url(params[:id]))
    else
      redirect_to('/')
    end
  end

  # POST /products
  # POST /products.xml
  def create
    if can_manage?
      @product = Product.new(params[:product])
      params[:product][:name].strip!
      params[:product][:name].downcase!
    end

    respond_to do |format|
      if can_manage?
        if @product.save
          expire_all_fragments
          flash[:notice] = 'Product was successfully created.'
          format.html { redirect_to(:controller => :products, :action => :show, :id => escape_url(@product.name)) }
        else
          format.html {
            render :action => "new"
          }
        end
      else
        format.html { redirect_to('/') }
      end
    end
  end

  # PUT /products/1
  # PUT /products/1.xml
  def update
    @product = Product.find(params[:id])
    params[:product][:name].strip!
    params[:product][:name].downcase!

    respond_to do |format|
      if @product.update_attributes(params[:product])
        expire_all_fragments
        flash[:notice] = 'Product was successfully updated.'
        format.html { redirect_to(:controller => :products, :action => :show, :id => escape_url(@product.name)) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @product.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.xml
  def destroy
    @product = Product.find(params[:id])
    @product.destroy

    Product.find_by_name(unescape_url(params[:id]))
    respond_to do |format|
      format.html { redirect_to(products_url) }
      format.xml { head :ok }
    end
  end

  def clone
    if request.post?
      session[:clone_review] = Hash.new
      unless params[:source_product_name].blank?
        session[:clone_review][:source_product_name] = params[:source_product_name].strip
      end
      
      unless params[:target_product_name].blank?      
        session[:clone_review][:target_product_name] = params[:target_product_name].strip
      end
      
      session[:clone_review][:scopes] = params[:scopes]
      session[:clone_review][:mark_options] = params[:mark_options]
      session[:clone_review][:mark_options] ||= []
      session[:clone_review][:label_option] = params[:label_option]
      session[:clone_review][:initial_mark_values] = params[:initial_mark_values]
      session[:clone_review][:marks] = params[:marks]
      session[:clone_review][:initial_label_value] = params[:initial_label_value]
      session[:clone_review][:label_selection_value] = params[:label_selection_value]
      session[:clone_review][:label_selection_value_global] = params[:label_selection_value_global]

      redirect_to :action => :clone_review, :id => escape_url(params[:source_product_name])
    else
      @product = Product.find_by_name(unescape_url(params[:id]))
    end
  end

  def clone_review

  end

  def process_clone
    mark_clone_in_progress
  end

  protected

  def clone_form_validation
    unless request.post?
      return
    end

    @error_message = []

    if params[:source_product_name].blank?
      @error_message << "Source product name not specified."
    end

    if params[:target_product_name].blank?
      @error_message << "Target product name not specified."
    #else
    #  @product = Product.find_by_name(unescape_url(params[:target_product_name].downcase.strip))
    #  if @product
    #    @error_message << "Target product name already used."
    #  end
    end
    
    if params[:source_product_name].strip == params[:target_product_name].strip
      @error_message << "product cannot be cloned to itself."
    end

    if params[:scopes].blank?
      @error_message << "Nothing set to clone."
    else
      if params[:scopes].include? 'package'
        if params[:label_option] == 'new_value'
          if params[:initial_label_value].blank?
            @error_message << "Initial label not set."
          elsif Label.find_in_global_scope(params[:initial_label_value].downcase.strip, unescape_url(params[:target_product_name]).downcase.strip)
            @error_message << "Initial label name already used."

          end
        end

        if !params[:mark_options].blank? && params[:mark_options].include?('new_value')
          if params[:initial_mark_values].blank?
            @error_message << "Initial marks not set."
          end
        end
      end
    end

    unless @error_message.blank?
      @product = Product.find_by_name(unescape_url(params[:source_product_name]))
      render :controller =>'products', :action => 'clone', :id => escape_url(params[:source_product_name])
    end
  end

end
