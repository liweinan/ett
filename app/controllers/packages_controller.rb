class PackagesController < ApplicationController
#  helper :sparklines
  before_filter :check_task, :only => [:new, :edit]
  before_filter :check_task_or_user, :only => [:export_to_csv]
  before_filter :user_view_index, :only => [:index]
  before_filter :check_can_manage, :only => [:destroy]
  before_filter :clone_form_validation, :only => :clone
  before_filter :deal_with_deprecated_brew_tag_id, :only => [:index, :show]

  # GET /packages
  # GET /packages.xml
  def index
    unless params[:task_id].blank?
      @packages = get_packages(unescape_url(params[:task_id]), unescape_url(params[:tag]), unescape_url(params[:status]), unescape_url(params[:user]))
    end

    respond_to do |format|
      params[:style] ||= nil
      params[:perspective] ||= nil
      format.html {
        if !params[:style].blank?
          if layout_exist?(params[:style])
            render params[:style], :layout => params[:style]
          else
            render params[:style]
          end

        elsif params[:task_id].blank?
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
        @package = Package.find_by_name_and_task_id(unescape_url(params[:id]), Task.find_by_name(unescape_url(params[:task_id])).id, :include => :p_attachments)
        if @package.blank?
          flash[:notice] = 'Package not found.'
          redirect_to("/tasks/#{escape_url(params[:task_id])}/packages")
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
    @package = Package.find_by_name_and_task_id(unescape_url(params[:id]), Task.find_by_name(unescape_url(params[:task_id])).id)
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

    @package.tags = process_tags(params[:tags], params[:package][:task_id])

    respond_to do |format|
      if @package.save
        expire_all_fragments
        flash[:notice] = 'Package was successfully created.'

        url = APP_CONFIG["site_prefix"] + "tasks/" + escape_url(@package.task.name) + "/packages/" + escape_url(@package.name)

        if Rails.env.production?

          if Setting.activated?(@package.task, Setting::ACTIONS[:created])
            Notify::Package.create(current_user, url, @package, Setting.all_recipients_of_package(@package, nil, :create))
          end

          unless params[:div_package_create_notification_area].blank?
            Notify::Package.create(current_user, url, @package, params[:div_package_create_notification_area])
          end
        end

        format.html { redirect_to(:controller => :packages, :action => :show,
                                  :id => escape_url(@package.name), :task_id => escape_url(@package.task.name), :user => params[:user]) }
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
    @orig_tags = @orig_package.tags.clone

    @package = Package.find(params[:id])

    params[:package] ||= Hash.new
    params[:package][:id] = @package.id


    if @package.created_by.blank?
      params[:package][:created_by] = current_user.id
    end

    params[:package][:updated_by] = current_user.id

    last_status_changed_at = @package.status_changed_at
    last_status = Status.find_by_id(@package.status_id)

    unless params[:package][:name].blank?
      cleanup_package_name(params[:package][:name])
    end

    respond_to do |format|
      Package.transaction do
        if @package.update_attributes(params[:package])

          @package.reload

          if params[:process_tags] == 'Yes'
            @package.tags = process_tags(params[:tags], @package.task_id)
          end

          # status changed
          new_status = Status.find_by_id(params[:package][:status_id].to_i)
          if new_status != last_status
            @package.status_changed_at = Time.now

            if !last_status.blank? && last_status.is_time_tracked?
              @tt = TrackTime.all(:conditions => ["package_id=? and status_id=?", @package.id, last_status.id])[0]
              @tt = TrackTime.new if @tt.blank?
              @tt.package_id = @package.id
              @tt.status_id = last_status.id

              last_status_changed_at ||= @package.status_changed_at
              @tt.time_consumed ||= 0
              @tt.time_consumed += (@package.status_changed_at.to_i - last_status_changed_at.to_i)/60
              @tt.save
            end

            unless new_status.blank?
              if new_status.code == Status::CODES[:inprogress]

                # the bug statuses are waiting to be updated according to https://docspace.corp.redhat.com/docs/DOC-148169
                @package.bz_bugs.each do |bz_bug|
                  #TODO if the assignee of this package is nil, the bug cannot be moved to assigned.
                  # TODO: check if the summary starts with Update to
                  update_bug(bz_bug.bz_id, params[:assignee], params[:user], params[pwd], 'ASSIGNED', oneway='true')
                  bz_bug.bz_action = BzBug::BZ_ACTIONS[:accepted]
                  bz_bug.save
                end

              elsif new_status.code == Status::CODES[:finished]
                # Dustin, please help to add codes here
                @package.bz_bugs.each do |bz_bug|
                  #TODO if the assignee of this package is nil, the bug cannot be moved to assigned.
                  # TODO: check if the summary starts with Update to
                  update_bug(bz_bug.bz_id, params[:assignee], params[:user], params[pwd], 'MODIFIED', oneway='true')
                  bz_bug.bz_action = BzBug::BZ_ACTIONS[:accepted]
                  bz_bug.save
                end
                # TODO: add some stuff
              end
            end


            log_entry = AutoLogEntry.new
            last_status_changed_at ||= @package.status_changed_at
            log_entry.start_time = last_status_changed_at
            log_entry.end_time = @package.status_changed_at
            log_entry.who = current_user
            log_entry.package = @package
            log_entry.status = last_status
            log_entry.save
          end

          xattrs = @package.task.setting.xattrs.split(',')

          if !@package.status.blank? &&
              @package.status.code == Status::CODES[:finished] &&
              xattrs.include?('mead') &&
              xattrs.include?('brew')
            brew_pkg = get_brew_name(@package)

            @package.brew = brew_pkg unless brew_pkg.nil?
            @package.mead = get_mead_name(brew_pkg) unless brew_pkg.nil?
          end

          @package.save

          Changelog.package_updated(@orig_package, @package, @orig_tags)

          do_sync(["name", "notes", "ver", "assignee", "brew_link", "group_id", "artifact_id", "project_name", "project_url", "license", "scm"])

          sync_status if params[:sync_status] == 'yes'
          sync_tags if params[:sync_tags] == 'yes'

          flash[:notice] = 'Package was successfully updated.'

          if Rails.env.production?
            url = ''

            if params[:request_path].blank?
              task_name = escape_url(@package.task.name)
              package_name = escape_url(@package.name)
              frag = "#{task_name}/packages/#{package_name}"
              url = generate_request_path(request, frag)
            else
              url = params[:request_path].gsub('/edit', '')
            end

            if Setting.activated?(@package.task, Setting::ACTIONS[:updated])
              Notify::Package.update(current_user, url, @package, Setting.all_recipients_of_package(@package, current_user, :edit))
            end

            unless params[:div_package_edit_notification_area].blank?
              Notify::Package.update(current_user, url, @package, params[:div_package_edit_notification_area])
            end
          end

          @output = true
        else
          unless @package.errors[:name].blank?
            @error_message = "Package #{@package.name} already exists. Here's the <a href='/tasks/#{escape_url(@package.task.name)}/packages/#{unescape_url(@package.name)}' target='_blank'>link</a>."
          end
          @user = params[:user]
          @output = false
        end
      end


      if @output == true
        expire_all_fragments
        format.html { redirect_to(:controller => :packages, :action => :show, :id => escape_url(@package.name), :task_id => escape_url(@package.task.name), :user => params[:user]) }
        format.js
      else
        format.html { render :action => :edit }
        format.js
      end
    end
  end

  def destroy
    expire_all_fragments
    @package = Package.find(params[:id])
    @package.updated_by = current_user.id
    @package.set_deleted

    respond_to do |format|
      format.html {
        #if params[:user].blank?
        #  redirect_to(:controller => :packages, :action => :index, :task_id => escape_url(@package.task.name))
        #else
        #  redirect_to(:controller => :packages, :action => :index, :task_id => escape_url(@package.task.name), :user => params[:user])
        #end

        redirect_to(:controller => :packages, :action => :show, :task_id => escape_url(@package.task.name), :id => escape_url(@package.name))
      }
    end
  end

  def clone
    if request.post?
      Package.transaction do
        source_task = Task.find_by_name(unescape_url(params[:task_id]))
        @source_package = Package.find_by_name_and_task_id(unescape_url(params[:id]), source_task.id)

        @source_package.updated_by = current_user.id
        @source_package.save

        @target_package = @source_package.clone
        target_task = Task.find_by_name(unescape_url(params[:target_task_name]))
        @target_package.task = target_task

        if params[:clone_assignee_option] == 'Yes'
          @target_package.assignee = @source_package.assignee
        end

        if params[:clone_status_option] == 'Yes'
          status_name = @source_package.status.name
          target_status = Status.find_in_global_scope(status_name, target_task.name)
          unless target_status
            target_status = @source_package.status.clone
            target_status.task = target_task
            target_status.save!
          end
          @target_package.status = target_status
        else
          @target_package.status = nil
        end

        if params[:clone_tags_option] == 'Yes'
          @source_package.tags.each do |source_tag|
            target_tag = Tag.find_by_key_and_task_id(source_tag.key, target_task.id)
            unless target_tag
              target_tag = source_tag.clone
              target_tag.task = target_task
              target_tag.save!
            end
            @target_package.tags << target_tag
          end

        else
          @target_package.tags = []
        end

        @target_package.updated_by = current_user.id
        @target_package.save!

        create_clone_relationship(@source_package, @target_package)
      end

      expire_all_fragments

      flash[:notice] = "Clone completed."

      redirect_to(:controller => :packages, :action => :show, :id => escape_url(@target_package.name), :task_id => escape_url(params[:target_task_name]))
    end
  end

  def export_to_csv

    require 'faster_csv'

    @packages = get_packages(unescape_url(params[:task_id]), unescape_url(params[:tag]), unescape_url(params[:status]), unescape_url(params[:user]))

    @task = Task.find_by_name(unescape_url(params[:task_id]))

    csv_string = FasterCSV.generate do |csv|
      # header row
      header_row = ["name", "status", "tags"]

      get_xattrs(@task, true, false) do |attr|
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
        if package.status.blank?
          val << ""
        else
          val << package.status.name
        end

        if package.tags.blank?
          val << ""
        else
          tag_val = ""
          package.tags.each do |tag|
            tag_val << tag.key + ", "
          end
          val << tag_val
        end

        get_xattrs(@task, true, false) do |attr|
          if package.read_attribute(attr).blank?
            val << ""
          else
            val << package.read_attribute(attr)
          end
        end

        csv << val
      end
    end

    # send it to the browser
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
    Package.transaction do
      @package = Package.find(params[:id])
      now = Time.now
      start_time = @package.time_point
      @package.time_consumed += ((now.to_i - @package.time_point) / 60)
      @package.time_point = 0
      @package.save

      log_entry = ManualLogEntry.new
      log_entry.start_time = Time.at(start_time)
      log_entry.end_time = Time.at(now)
      log_entry.who = current_user
      log_entry.package = @package
      log_entry.save
    end
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

  def sync_tags
    @package.all_relationships_of('clone').each do |target_package|
      unless @package.tags.blank?
        target_tags = []
        @package.tags.each do |source_tag|
          target_tag = Tag.find_by_key_and_task_id(source_tag.key, target_package.task_id)
          unless target_tag.blank?
            target_tags << target_tag
          else
            target_tag = source_tag.clone
            target_tag.task_id = target_package.task_id
            target_tag.save
            target_tags << target_tag
          end
        end
        target_package.tags = target_tags
        target_package.save
      else
        target_package.tags = nil
        target_package.save
      end
    end
  end

  def sync_status
    @package.all_relationships_of('clone').each do |target_package|
      unless @package.status.blank?
        target_status = Status.find_in_global_scope(@package.status.name, target_package.task.name)
        unless target_status.blank?
          target_package.status = target_status
          target_package.save
        else
          target_status = @package.status.clone
          target_status.task = target_package.task
          target_status.save
          target_package.status = target_status
          target_package.save
        end
      else # User has unset the status of source package, so we unset all the statuses assigned to target packages.
        target_package.status = nil
        target_package.save
      end
    end
  end

  def clone_form_validation
    unless request.post?
      return
    end

    @error_message = []

    target_task = Task.find_by_name(unescape_url(params[:target_task_name]))

    if target_task.blank?
      @error_message << "Target task not found."

    else

      if Package.find_by_name_and_task_id(unescape_url(params[:id]), target_task.id)
        @error_message << "Package already exists in target task."
      end
    end

    unless @error_message.blank?
      render :controller => 'packages', :action => 'clone', :id => escape_url(params[:id]), :task_id => escape_url(params[:task_id])
    end

  end

  def cleanup_package_name(name)
    unless name.blank?
      name.strip!
#      name.downcase!
    end
  end

  def user_view_index
    if !params[:user].blank? && params[:task_id].blank?
      redirect_to(:controller => :user_views, :action => :index, :user_id => User.find_by_email(params[:user]).name)
    end
  end

  def get_packages(__task_name, __tag_key, __status_name, __user_email)
    order = "status_id, name"

    hierarchy = "select id from tasks where name = '#{__task_name}'"

    __statuses_can_show_sql = " AND (p.status_id IN (#{Status.ids_can_show_by_task_name_in_global_scope(__task_name)}) OR p.status_id IS NULL)"

    @all_packages_count = Package.count_by_sql("select count(*) from packages p where p.task_id IN (#{hierarchy}) #{__statuses_can_show_sql}")

    if logged_in?
      @my_packages_count = Package.count_by_sql("select count(*) from packages p where p.task_id IN (#{hierarchy}) AND p.user_id = #{session[:current_user].id} #{__statuses_can_show_sql}")
    end

    opts = ''
    unless __user_email.blank?
      opts = "AND p.user_id = #{User.find_by_email(__user_email).id} "
    end

    opts << __statuses_can_show_sql

    if !__status_name.blank? && !__tag_key.blank?
      tag = Tag.find_by_key_and_task_id(__tag_key, Task.find_by_name(__task_name).id)
      _status = Status.find_in_global_scope(__status_name, __task_name)
      _packages = Package.find_by_sql("select p.* from packages p join assignments a on p.id = a.package_id and a.tag_id = #{tag.id} and status_id = #{_status.id} and p.task_id IN (#{hierarchy}) #{opts} order by #{order}")
    elsif !__status_name.blank?
      _packages = Package.find_by_sql("select p.* from packages p where p.status_id = #{Status.find_in_global_scope(__status_name, __task_name).id} AND p.task_id IN (#{hierarchy}) #{opts} order by #{order}")
    elsif !__tag_key.blank?
      tag = Tag.find_by_key_and_task_id(__tag_key, Task.find_by_name(__task_name))
      _packages = Package.find_by_sql("select p.* from packages p join assignments a on p.id = a.package_id and a.tag_id = #{tag.id} and p.task_id IN (#{hierarchy}) #{opts} order by #{order}")
    else
      _packages = Package.find_by_sql("select p.* from packages p where p.task_id IN (#{hierarchy}) #{opts} order by #{order}")
    end
    _packages
  end

  def deal_with_deprecated_brew_tag_id
    unless params[:brew_tag_id].blank?
      params[:task_id] = params[:brew_tag_id]
    end
  end

end
