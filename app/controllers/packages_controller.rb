class PackagesController < ApplicationController
#  helper :sparklines
  before_filter :check_tag, :only => [:new, :edit]
  before_filter :check_tag_or_user, :only => [:export_to_csv]
  before_filter :user_view_index, :only => [:index]
  before_filter :check_can_manage, :only => [:destroy]
  before_filter :clone_form_validation, :only => :clone

  # GET /packages
  # GET /packages.xml
  def index
    unless params[:brew_tag_id].blank?
      @packages = get_packages(unescape_url(params[:brew_tag_id]), unescape_url(params[:mark]), unescape_url(params[:label]), unescape_url(params[:user]))
    end

    respond_to do |format|
      params[:style] ||= nil
      format.html {
        if !params[:style].blank?
          render params[:style], :layout => params[:style]
        elsif params[:brew_tag_id].blank?
          render 'layouts/welcome'
        end
      }
    end
  end


  # GET /packages/1
  # GET /packages/1.xml
  def show
    respond_to do |format|
      format.html {
        @package = Package.find_by_name_and_brew_tag_id(unescape_url(params[:id]), BrewTag.find_by_name(unescape_url(params[:brew_tag_id])).id, :include => :p_attachments)
        if @package.blank?
          flash[:notice] = 'Package not found.'
          redirect_to("/brew_tags/#{escape_url(params[:brew_tag_id])}/packages")
        end
      }
      format.xml { render :xml => @package }
    end
  end

  # GET /packages/new
  # GET /packages/new.xml
  def new
    @package = Package.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /packages/1/edit
  def edit
    @package = Package.find_by_name_and_brew_tag_id(unescape_url(params[:id]), BrewTag.find_by_name(unescape_url(params[:brew_tag_id])).id)
    #@package.revert_to(params[:version].to_i) unless params[:version].blank?
    unless can_edit_package? @package
      redirect_to('/')
    end
  end

  # POST /packages
  # POST /packages.xml
  def create
    @package = Package.new(params[:package])
    cleanup_package_name(@package.name)

    @package.created_by = current_user.id
    @package.updated_by = current_user.id

    @package.marks = process_marks(params[:marks], params[:package][:brew_tag_id])

    respond_to do |format|
      if @package.save
        expire_all_fragments
        flash[:notice] = 'Package was successfully created.'

        url = APP_CONFIG["site_prefix"] + "brew_tags/" + escape_url(@package.brew_tag.name) + "/packages/" + escape_url(@package.name)

        if Rails.env.production?
          if Setting.activated?(@package.brew_tag, Setting::ACTIONS[:created])
            Notify::Package.create(current_user, url, @package, Setting.all_recipients_of_package(@package, nil, :create))
          end

          unless params[:div_package_create_notification_area].blank?
            Notify::Package.create(current_user, url, @package, params[:div_package_create_notification_area])
          end
        end

        format.html { redirect_to(:controller => :packages, :action => :show,
                                  :id => escape_url(@package.name), :brew_tag_id => escape_url(@package.brew_tag.name), :user => params[:user]) }
      else

        @user = params[:user]
        format.html { render :action => :new }
      end
    end
  end


  # PUT /packages/1
  # PUT /packages/1.xml
  def update

    # for Changelog.package_updated
    @orig_package = Package.find(params[:id])
    @orig_marks = @orig_package.marks.clone

    @package = Package.find(params[:id])

    params[:package] ||= Hash.new
    params[:package][:id] = @package.id


    if @package.created_by.blank?
      params[:package][:created_by] = current_user.id
    end

    params[:package][:updated_by] = current_user.id

    last_label_changed_at = @package.label_changed_at
    last_label = Label.find_by_id(@package.label_id)

    unless params[:package][:name].blank?
      cleanup_package_name(params[:package][:name])
    end

    respond_to do |format|
      Package.transaction do
        if @package.update_attributes(params[:package])

          @package.reload
          @package.marks = process_marks(params[:marks], @package.brew_tag_id)

          # label changed
          if Label.find_by_id(params[:package][:label_id].to_i) != last_label
            @package.label_changed_at = Time.now

            if !last_label.blank? && last_label.is_time_tracked?
              @tt = TrackTime.all(:conditions => ["package_id=? and label_id=?", @package.id, last_label.id])[0]
              @tt = TrackTime.new if @tt.blank?
              @tt.package_id=@package.id
              @tt.label_id=last_label.id

              last_label_changed_at ||= @package.label_changed_at
              @tt.time_consumed ||= 0
              @tt.time_consumed += (@package.label_changed_at.to_i - last_label_changed_at.to_i)/60
              @tt.save
            end
          end

          @package.save

          Changelog.package_updated(@orig_package, @package, @orig_marks)

          do_sync(["name", "notes", "ver", "assignee", "brew_link", "group_id", "artifact_id", "project_name", "project_url", "license", "scm"])

          sync_label if params[:sync_label] == 'yes'
          sync_marks if params[:sync_marks] == 'yes'

          flash[:notice] = 'Package was successfully updated.'

          if  Rails.env.production?
            ### TODO HACK HACK! this should be fixed, ajax update call in list page should also be able to send notification!
            unless params[:request_path].blank?
              url = params[:request_path].sub(/\/edit$/, '')

              if Setting.activated?(@package.brew_tag, Setting::ACTIONS[:updated])
                Notify::Package.update(current_user, url, @package, Setting.all_recipients_of_package(@package, current_user, :edit))
              end

              unless params[:div_package_edit_notification_area].blank?
                Notify::Package.update(current_user, url, @package, params[:div_package_edit_notification_area])
              end
            end
          end

          @output = true
        else
          unless @package.errors[:name].blank?
            @error_message = "Package #{@package.name} already exists. Here's the <a href='/brew_tags/#{escape_url(@package.brew_tag.name)}/packages/#{unescape_url(@package.name)}' target='_blank'>link</a>."
          end
          @user = params[:user]
          @output = false

        end
      end


      if @output == true
        expire_all_fragments
        format.html { redirect_to(:controller => :packages, :action => :show, :id => escape_url(@package.name), :brew_tag_id => escape_url(@package.brew_tag.name), :user => params[:user]) }
        format.js
      else
        format.html { render :action => :edit }
        format.js
      end
    end
  end

  #DELETE /packages/1
  #DELETE /packages/1.xml
  def destroy
    expire_all_fragments
    @package = Package.find(params[:id])
    @package.updated_by = current_user.id
    @package.set_deleted

    respond_to do |format|
      format.html {
        #if params[:user].blank?
        #  redirect_to(:controller => :packages, :action => :index, :brew_tag_id => escape_url(@package.brew_tag.name))
        #else
        #  redirect_to(:controller => :packages, :action => :index, :brew_tag_id => escape_url(@package.brew_tag.name), :user => params[:user])
        #end

        redirect_to(:controller => :packages, :action => :show, :brew_tag_id => escape_url(@package.brew_tag.name), :id => escape_url(@package.name))
      }
    end
  end

  def clone
    if request.post?
      Package.transaction do
        source_tag = BrewTag.find_by_name(unescape_url(params[:brew_tag_id]))
        @source_package = Package.find_by_name_and_brew_tag_id(unescape_url(params[:id]), source_tag.id)

        @source_package.updated_by = current_user.id
        @source_package.save

        @target_package = @source_package.clone
        target_tag = BrewTag.find_by_name(unescape_url(params[:target_tag_name]))
        @target_package.brew_tag = target_tag

        if params[:clone_assignee_option] == 'Yes'
          @target_package.assignee = @source_package.assignee
        end

        if params[:clone_label_option] == 'Yes'
          label_name = @source_package.label.name
          target_label = Label.find_in_global_scope(label_name, target_tag.name)
          unless target_label
            target_label = @source_package.label.clone
            target_label.brew_tag = target_tag
            target_label.save!
          end
          @target_package.label = target_label
        else
          @target_package.label = nil
        end

        if params[:clone_marks_option] == 'Yes'
          @source_package.marks.each do |source_mark|
            target_mark = Mark.find_by_key_and_brew_tag_id(source_mark.key, target_tag.id)
            unless target_mark
              target_mark = source_mark.clone
              target_mark.brew_tag = target_tag
              target_mark.save!
            end
            @target_package.marks << target_mark
          end

        else
          @target_package.marks = []
        end

        @target_package.updated_by = current_user.id
        @target_package.save!

        create_clone_relationship(@source_package, @target_package)
      end

      expire_all_fragments

      flash[:notice] = "Clone completed."

      redirect_to(:controller => :packages, :action => :show, :id => escape_url(@target_package.name), :brew_tag_id => escape_url(params[:target_tag_name]))
    end
  end

  def export_to_csv

    require 'faster_csv'

    @packages = get_packages(unescape_url(params[:brew_tag_id]), unescape_url(params[:mark]), unescape_url(params[:label]), unescape_url(params[:user]))

    @brew_tag = BrewTag.find_by_name(unescape_url(params[:brew_tag_id]))

    csv_string = FasterCSV.generate do |csv|
      # header row
      header_row = ["name", "label", "marks"]

      get_xattrs(@brew_tag, true, false) do |attr|
        if attr.blank?
          header_row << ""
        else
          header_row << attr.downcase
        end
      end

      csv << header_row

      # data rows
      @packages.each do |package|

        val = [package.name]
        if package.label.blank?
          val << ""
        else
          val << package.label.name
        end

        if package.marks.blank?
          val << ""
        else
          mark_val = ""
          package.marks.each do |mark|
            mark_val << mark.key + ", "
          end
          val << mark_val
        end

        get_xattrs(@brew_tag, true, false) do |attr|
          if package.read_attribute(attr).blank?
            val << ""
          else
            val << package.read_attribute(attr)
          end
        end

        csv << val
      end
    end

    # send it to the browsah
    send_data csv_string,
              :type => 'text/csv; charset=iso-8859-1; header=present',
              :disposition => "attachment; filename=packages_#{Time.now.to_i}.csv"
  end

  def start_progress
    @package = Package.find(params[:id])
    @package.time_point = Time.now.to_i
    @package.save
    respond_to do |format|
      format.js
    end
  end


  def stop_progress
    @package = Package.find(params[:id])

    @package.time_consumed += ((Time.now.to_i - @package.time_point) / 60)
    @package.time_point = 0
    @package.save

    respond_to do |format|
      format.js
    end
  end

  protected

  def do_sync(fields)
    fields.each do |field|
      if params["sync_#{field}"] == 'yes'
        @package.all_relationships_of('clone').each do |package|
          package.write_attribute(field, @package.read_attribute(field))
          package.save
        end
      end
    end
  end

  def sync_marks
    @package.all_relationships_of('clone').each do |target_package|
      unless @package.marks.blank?
        target_marks = []
        @package.marks.each do |source_mark|
          target_mark = Mark.find_by_key_and_brew_tag_id(source_mark.key, target_package.brew_tag_id)
          unless target_mark.blank?
            target_marks << target_mark
          else
            target_mark = source_mark.clone
            target_mark.brew_tag_id = target_package.brew_tag_id
            target_mark.save
            target_marks << target_mark
          end
        end
        target_package.marks = target_marks
        target_package.save
      else
        target_package.marks = nil
        target_package.save
      end
    end
  end

  def sync_label
    @package.all_relationships_of('clone').each do |target_package|
      unless @package.label.blank?
        target_label = Label.find_in_global_scope(@package.label.name, target_package.brew_tag.name)
        unless target_label.blank?
          target_package.label = target_label
          target_package.save
        else
          target_label = @package.label.clone
          target_label.brew_tag = target_package.brew_tag
          target_label.save
          target_package.label = target_label
          target_package.save
        end
      else # User has unset the label of source package, so we unset all the labels assigned to target packages.
        target_package.label = nil
        target_package.save
      end
    end
  end

  def clone_form_validation
    unless request.post?
      return
    end

    @error_message = []

    target_tag = BrewTag.find_by_name(unescape_url(params[:target_tag_name]))

    if target_tag.blank?
      @error_message << "Target tag not found."

    else

      if Package.find_by_name_and_brew_tag_id(unescape_url(params[:id]), target_tag.id)
        @error_message << "Package already exists in target tag."
      end
    end

    unless @error_message.blank?
      render :controller => 'packages', :action => 'clone', :id => escape_url(params[:id]), :brew_tag_id => escape_url(params[:brew_tag_id])
    end

  end

  def cleanup_package_name(name)
    unless name.blank?
      name.strip!
#      name.downcase!
    end
  end

  def user_view_index
    if !params[:user].blank? && params[:brew_tag_id].blank?
      redirect_to(:controller => :user_views, :action => :index, :user_id => User.find_by_email(params[:user]).name)
    end
  end

  def get_packages(__brew_tag_name, __mark_key, __label_name, __user_email)
    order = "label_id, name"

    hierarchy = "select id from brew_tags where name = '#{__brew_tag_name}'"

    __labels_can_show_sql = " AND (p.label_id IN (#{Label.ids_can_show_by_brew_tag_name_in_global_scope(__brew_tag_name)}) OR p.label_id IS NULL)"

    @all_packages_count = Package.count_by_sql("select count(*) from packages p where p.brew_tag_id IN (#{hierarchy}) #{__labels_can_show_sql}")

    if logged_in?
      @my_packages_count = Package.count_by_sql("select count(*) from packages p where p.brew_tag_id IN (#{hierarchy}) AND p.user_id = #{session[:current_user].id} #{__labels_can_show_sql}")
    end

    opts = ''
    unless __user_email.blank?
      opts = "AND p.user_id = #{User.find_by_email(__user_email).id} "
    end

    opts << __labels_can_show_sql

    if !__label_name.blank? && !__mark_key.blank?
      mark = Mark.find_by_key_and_brew_tag_id(__mark_key, BrewTag.find_by_name(__brew_tag_name).id)
      _label = Label.find_in_global_scope(__label_name, __brew_tag_name)
      _packages = Package.find_by_sql("select p.* from packages p join assignments a on p.id = a.package_id and a.mark_id = #{mark.id} and label_id = #{_label.id} and p.brew_tag_id IN (#{hierarchy}) #{opts} order by #{order}")
    elsif !__label_name.blank?
      _packages = Package.find_by_sql("select p.* from packages p where p.label_id = #{Label.find_in_global_scope(__label_name, __brew_tag_name).id} AND p.brew_tag_id IN (#{hierarchy}) #{opts} order by #{order}")
    elsif !__mark_key.blank?
      mark = Mark.find_by_key_and_brew_tag_id(__mark_key, BrewTag.find_by_name(__brew_tag_name))
      _packages = Package.find_by_sql("select p.* from packages p join assignments a on p.id = a.package_id and a.mark_id = #{mark.id} and p.brew_tag_id IN (#{hierarchy}) #{opts} order by #{order}")
    else
      _packages = Package.find_by_sql("select p.* from packages p where p.brew_tag_id IN (#{hierarchy}) #{opts} order by #{order}")
    end
    _packages
  end

end