class BrewTagsController < ApplicationController
  before_filter :check_can_manage, :only => [:create, :update, :new, :edit, :clone, :clone_review]
  before_filter :clone_form_validation, :only => :clone

  # GET /brew_tags
  # GET /brew_tags.xml
  def index
    @brew_tags = BrewTag.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @brew_tags }
    end
  end

  # GET /brew_tags/1
  # GET /brew_tags/1.xml
  def show
    @brew_tag = BrewTag.find_by_name(unescape_url(params[:id]))

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @brew_tag }
    end
  end

  # GET /brew_tags/new
  # GET /brew_tags/new.xml
  def new
    if can_manage?
      @brew_tag = BrewTag.new
    end

    respond_to do |format|
      format.html {
        unless can_manage?
          redirect_to('/')
        end
      }
      format.xml { render :xml => @brew_tag }
    end
  end

  # GET /brew_tags/1/edit
  def edit
    if can_manage?
      @brew_tag = BrewTag.find_by_name(unescape_url(params[:id]))
    else
      redirect_to('/')
    end
  end

  # POST /brew_tags
  # POST /brew_tags.xml
  def create
    if can_manage?
      @brew_tag = BrewTag.new(params[:brew_tag])
      params[:brew_tag][:name].strip!
      params[:brew_tag][:name].downcase!
    end

    respond_to do |format|
      if can_manage?
        if @brew_tag.save
          expire_all_fragments
          flash[:notice] = 'BrewTag was successfully created.'
          format.html { redirect_to(:controller => :brew_tags, :action => :show, :id => escape_url(@brew_tag.name)) }
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

  # PUT /brew_tags/1
  # PUT /brew_tags/1.xml
  def update
    @brew_tag = BrewTag.find(params[:id])
    params[:brew_tag][:name].strip!
    params[:brew_tag][:name].downcase!

    respond_to do |format|
      if @brew_tag.update_attributes(params[:brew_tag])
        expire_all_fragments
        flash[:notice] = 'BrewTag was successfully updated.'
        format.html { redirect_to(:controller => :brew_tags, :action => :show, :id => escape_url(@brew_tag.name)) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @brew_tag.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /brew_tags/1
  # DELETE /brew_tags/1.xml
  def destroy
    @brew_tag = BrewTag.find(params[:id])
    @brew_tag.destroy

    BrewTag.find_by_name(unescape_url(params[:id]))
    respond_to do |format|
      format.html { redirect_to(brew_tags_url) }
      format.xml { head :ok }
    end
  end

  def clone
    if request.post?
      session[:clone_review] = Hash.new
      unless params[:source_tag_name].blank?
        session[:clone_review][:source_tag_name] = params[:source_tag_name].strip
      end
      
      unless params[:target_tag_name].blank?      
        session[:clone_review][:target_tag_name] = params[:target_tag_name].strip
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

      redirect_to :action => :clone_review, :id => escape_url(params[:source_tag_name])
    else
      @brew_tag = BrewTag.find_by_name(unescape_url(params[:id]))
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

    if params[:source_tag_name].blank?
      @error_message << "Source tag name not specified."
    end

    if params[:target_tag_name].blank?
      @error_message << "Target tag name not specified."
    #else
    #  @brew_tag = BrewTag.find_by_name(unescape_url(params[:target_tag_name].downcase.strip))
    #  if @brew_tag
    #    @error_message << "Target tag name already used."
    #  end
    end
    
    if params[:source_tag_name].strip == params[:target_tag_name].strip
      @error_message << "Tag cannot be cloned to itself."
    end

    if params[:scopes].blank?
      @error_message << "Nothing set to clone."
    else
      if params[:scopes].include? 'package'
        if params[:label_option] == 'new_value'
          if params[:initial_label_value].blank?
            @error_message << "Initial label not set."
          elsif Label.find_in_global_scope(params[:initial_label_value].downcase.strip, unescape_url(params[:target_tag_name]).downcase.strip)
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
      @brew_tag = BrewTag.find_by_name(unescape_url(params[:source_tag_name]))
      render :controller =>'brew_tags', :action => 'clone', :id => escape_url(params[:source_tag_name])
    end
  end

end
