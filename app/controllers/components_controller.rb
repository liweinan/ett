class ComponentsController < ApplicationController
  before_filter :check_can_manage, :only => [:edit, :new]

  def index
  end

  def new
    @component = Component.new
  end

  def edit
    @component = Component.find_by_name(unescape_url(params[:id]))
    @brew_tag_names = []
    @component.brew_tags.each do |tag|
      @brew_tag_names << tag.name
    end
  end

  def create
    expire_all_fragments
    @component = Component.new(params[:component])
    @component.brew_tags = collect_brew_tags(params[:brew_tag_names])

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
        @component.brew_tags = collect_brew_tags(params[:brew_tag_names])
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
      @packages = Package.distinct_in_tags_can_show(@component.brew_tags)
    end

  end

  protected

  def collect_brew_tags(tag_names)
    unless tag_names.blank?
      brew_tags = []
      tag_names.each do |tag_name|
        brew_tags << BrewTag.find_by_name(tag_name)
      end
      return brew_tags
    end
    []
  end

end
