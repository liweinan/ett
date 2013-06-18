class ComponentsController < ApplicationController
  before_filter :check_can_manage, :only => [:edit, :new]

  def index
  end

  def new
    @component = Component.new
  end

  def edit
    @component = Component.find_by_name(unescape_url(params[:id]))
    @product_names = []
    @component.products.each do |tag|
      @product_names << tag.name
    end
  end

  def create
    expire_all_fragments
    @component = Component.new(params[:component])
    @component.products = collect_products(params[:product_names])

    respond_to do |format|
      if @component.save
        format.html { redirect_to(:action => :show, :id => escape_url(@component.name), :notice => 'Component was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    expire_all_fragments
    @component = Component.find(params[:id])
    respond_to do |format|
      if @component.update_attributes(params[:component])
        @component.products = collect_products(params[:product_names])
        @component.save

        flash[:notice] = 'Component was successfully updated.'
        format.html { render :action => "updated" }
      else
        format.html { render :action => "edit" }
      end
    end

  end

  def destroy
    @component = Component.find(params[:id])
    @component.destroy

    respond_to do |format|
      format.html { redirect_to(components_url) }
    end
  end


  def show
    @component = Component.find_by_name(unescape_url(params[:id]))
    if @component.blank?
      redirect_to(:action => :index)
    else
      @packages = Package.distinct_in_tags_can_show(@component.products)
    end

  end

  protected

  def collect_products(tag_names)
    unless tag_names.blank?
      products = []
      tag_names.each do |tag_name|
        products << Product.find_by_name(tag_name)
      end
      return products
    end
    []
  end

end
