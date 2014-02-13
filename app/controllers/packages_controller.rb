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
      @packages = get_pacs(params)
    end

    respond_to do |format|
      params[:style] ||= nil
      params[:perspective] ||= nil
      format.html do
        if !params[:style].blank?
          render params[:style]
        elsif params[:task_id].blank?
          render 'layouts/welcome'
        end
      end
    end
  end

  def get_pacs(params)
    get_packages(unescape_url(params[:task_id]),
                 unescape_url(params[:tag]),
                 unescape_url(params[:status]),
                 unescape_url(params[:user]))
  end


  # GET /packages/1
  # GET /packages/1.xml
  def show
    respond_to do |format|
      format.html {
        @package = Package.find_by_name_and_task_id(unescape_url(params[:id]),
                                                    find_task(params[:task_id]).id,
                                                    :include => :p_attachments)
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

    @package.task = find_task(params[:task_id]) unless params[:task_id].blank?

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /packages/1/edit
  def edit
    @package = Package.find_by_name_and_task_id(unescape_url(params[:id]),
                                                find_task(params[:task_id]).id)
    redirect_to('/') unless can_edit_package? @package
  end

  # POST /packages
  # POST /packages.xml
  def create
    @package = Package.new(params[:package])
    cleanup_pac_name!(@package.name)

    @package.created_by = current_user.id
    @package.updated_by = current_user.id

    @package.tags = process_tags(params[:tags], params[:package][:task_id])

    respond_to do |format|
      if @package.save
        expire_all_fragments
        flash[:notice] = 'Package was successfully created.'

        if Rails.env.production?
          notify_package_created(params, @package)
        end

        format.html { show_package(params, @package) }
      else
        @user = params[:user]
        format.html { render :action => :new }
      end
    end
  end

  def show_package(params, package)
    redirect_to(:controller => :packages,
                :action => :show,
                :id => escape_url(package.name),
                :task_id => escape_url(package.task.name),
                :user => params[:user])
  end

  def notify_package_created(params, package)
    url = get_package_link(params, package, :create)

    if Setting.activated?(package.task, Setting::ACTIONS[:created])
      Notify::Package.create(current_user,
                             url,
                             package,
                             Setting.all_recipients_of_package(package, nil, :create))
    end

    unless params[:div_package_create_notification_area].blank?
      Notify::Package.create(current_user,
                             url,
                             package,
                             params[:div_package_create_notification_area])
    end
  end

  # list of 2 elements, first element is bz_user, and second element is
  # bz_password
  def bz_user_pass(params, session)
    [extract_username(params[:bzauth_user]), session[:bz_pass]]
  end

  # PUT /packages/1
  # PUT /packages/1.xml
  # params[:flatten_bzs] seems to be only used for inline bugzilla
  # params[:process_tags] ??
  def update

    update_bz_pass(params[:bzauth_pwd])
    bz_cred = bz_user_pass(params, session)
    shared_inline_bzs = get_shared_inline_bz(params[:flatten_bzs])

    # for Changelog.package_updated
    @orig_package = Package.find(params[:id])
    @package = Package.find(params[:id])

    @orig_tags = @orig_package.tags.clone

    update_params_hash!(params, @package)

    # Function to support inline editor to update BZ
    # Input syntax: <Bz1Id> <Bz2Id> <Bz3Id>
    update_inline_bz(bz_cred, shared_inline_bzs, @package)

    last_status_changed_at = @package.status_changed_at
    last_status = Status.find_by_id(@package.status_id)

    old_assignee_email = @package.assignee.email if @package.assignee
    assignee_email = new_assignee_email(params)

    old_version = @package.ver
    current_ver = get_current_version(params)

    respond_to do |format|
      Package.transaction do
        if shared_inline_bzs.blank?
          @package.update_attributes(params[:package])

          @package.reload
          # this is needed since we write to @package later in this section of
          # the code. (@package.status_changed_at = Time.now). This messes up
          # with the latest_changes command since the latest_change will be that
          # instead of what the user changed in the website.
          latest_changes_package = @package.latest_changes
          update_tags(params, @package)

          # update the assignee of the bugs if assignee changed
          # TODO: we don't check whether the bz_bug assignee is the same as the old
          # one. Will have to fix this someday
          update_bz_assignee_and_version(old_assignee_email, assignee_email,
                                         old_version, current_ver,
                                         bz_cred, @package)

          # status changed
          status_changed_actions(assignee_email,
                                 last_status, last_status_changed_at,
                                 bz_cred,
                                 @package, params)

          @package.save

          Changelog.package_updated(@orig_package, @package, @orig_tags)

          do_sync(%w(name notes ver assignee brew_link group_id artifact_id project_name project_url license scm))

          sync_actions(params)

          flash[:notice] = 'Package was successfully updated.'

          if Rails.env.production?
            notify_package_updated(latest_changes_package, params, @package)
          end

          @output = true
        else
          unless @package.errors[:name].blank?
            @error_message = duplicate_package_msg(@package)
          end
          @user = params[:user]
          @output = false
        end
      end

      if @output
        expire_all_fragments
        format.html { show_package(params, @package) }
        format.js
      else
        format.html { render :action => :edit }
        format.js
      end
    end
  end

  def duplicate_package_msg(package)
    "Package #{package.name} already exists. Here's the " \
    "<a href='/tasks/#{escape_url(package.task.name)}/packages/#{unescape_url(package.name)}'" \
    " target='_blank'>link</a>."
  end

  def sync_actions(params)
    sync_status if params[:sync_status] == 'yes'
    sync_tags if params[:sync_tags] == 'yes'
  end

  def status_changed_actions(assignee_email, last_status,
      last_status_changed, bz_cred, package, params)
    new_status = get_new_status(params)
    if new_status != last_status
      last_status_changed = time_track_package(last_status,
                                               last_status_changed,
                                               package)
      ####################################################################
      ############################ Bugzilla ##############################
      ####################################################################
      update_bz_status_if_status_changed(assignee_email, new_status,
                                         bz_cred, package)
      ####################################################################
      ####################################################################
      @package.update_log_entry(last_status, last_status_changed, current_user)
    end
  end

  def update_bz_assignee_and_version(old_assignee_email, assignee_email,
      old_version, current_ver, bz_cred, package)
    if Rails.env.production?
      if old_assignee_email != assignee_email
        update_bz_assignee(assignee_email, bz_cred, package)
      end

      if version_changed(current_ver, old_version)
        update_bz_version(current_ver, old_version, bz_cred, package)
      end
    end
  end

  def update_bz_status_if_status_changed(assignee_email, new_status,
      bz_cred, package)

    if !new_status.blank? # && Rails.env.production?
      if status_in_progress(assignee_email, new_status)

        # the bug statuses are waiting to be updated according to
        # https://docspace.corp.redhat.com/docs/DOC-148169
        # TODO we need to write some unit tests to test all the
        # integrations with SOA
        #update_bz_status(assignee_email, bz_cred, package)
      elsif status_in_finished(new_status)
        package.update_mead_information

        #update_bz_status_finished(assignee_email, bz_cred, package)
      end
    end
  end


  def status_in_finished(new_status)
    new_status.code == Status::CODES[:finished]
  end

  def status_in_progress(assignee_email, new_status)
    new_status.code == Status::CODES[:inprogress] && !assignee_email.blank?
  end

  def get_new_status(params)
    Status.find_by_id(params[:package][:status_id].to_i)
  end

  def version_changed(current_ver, old_version)
    !current_ver.nil? &&
        !old_version.nil? &&
        current_ver != old_version
  end

  def get_current_version(params)
    params[:package][:ver] if params[:package].key?(:ver)
  end

  def new_assignee_email(params)
    if params[:package].key?(:user_id) && !params[:package][:user_id].blank?
      User.find_by_id(params[:package][:user_id]).email
    else
      ''
    end
  end

  def update_bz_status_finished(assignee_email, bz_cred, package)

    shared_bz_user, shared_bz_pass = bz_cred
    package.bz_bugs.each do |bz_bug|
      if upgrade_bz?(assignee_email, bz_bug, package)

        assignee_email = package.get_bz_email

        params_bz = {:milestone => package.task.milestone,
                     :assignee => assignee_email,
                     :userid => shared_bz_user,
                     :status => BzBug::BZ_STATUS[:modified],
                     :pwd => shared_bz_pass}

        update_rhel6_bz(bz_bug, package, params_bz)

        add_comment_milestone_status_to_bug(bz_bug.bz_id, params_bz)

        bz_bug.bz_action = BzBug::BZ_ACTIONS[:accepted]
        bz_bug.save
      end
    end
  end

  def update_rhel6_bz(bz_bug, package, params_bz)
    if bz_bug.summary.match(/RHEL6/)
      comment = package.generate_bz_comment
      params_bz[:comment] = comment
    end
  end

  def upgrade_bz?(assignee_email, bz_bug, package)
    bz_bug.summary.match(/Upgrade/) &&
    (bz_bug.bz_assignee == assignee_email ||
    bz_bug.bz_assignee == package.assignee.bugzilla_email)
  end

  def update_bz_status(assignee_email, bz_cred, package)
    shared_bz_user, shared_bz_pass = bz_cred
    package.bz_bugs.each do |bz_bug|
      if upgrade_bz?(assignee_email, bz_bug, package)

        assignee_email = package.get_bz_email

        params_bz = {:assignee => assignee_email,
                     :userid => shared_bz_user,
                     :pwd => shared_bz_pass,
                     :status => BzBug::BZ_STATUS[:assigned]}

        update_bug(bz_bug.bz_id, oneway='true', params_bz)
        bz_bug.bz_action = BzBug::BZ_ACTIONS[:accepted]
        bz_bug.save
      end
    end
  end

  def update_bz_version(current_ver, old_version, bz_cred, package)
    shared_bz_user, shared_bz_pass = bz_cred
    errata_bzs = package.upgrade_bz
    errata_bzs.each do |errata_bz|
      new_errata_bz_summary = errata_bz.summary.gsub(old_version,
                                                     current_ver)

      params_bz = {:userid => shared_bz_user,
                   :pwd => shared_bz_pass,
                   :summary => new_errata_bz_summary}

      update_bug_summary(errata_bz.bz_id, oneway='true', params_bz)
      errata_bz.bz_action = BzBug::BZ_ACTIONS[:accepted]
      errata_bz.save
    end
  end

  def update_bz_assignee(assignee_email, bz_cred, package)

    shared_bz_user, shared_bz_pass = bz_cred
    package.bz_bugs.each do |bz_bug|
      if upgrade_bz2?(assignee_email, bz_bug)

        assignee_email = package.get_bz_email

        params_bz = {:assignee => assignee_email,
                     :userid => shared_bz_user,
                     :pwd => shared_bz_pass,
                     :status => BzBug::BZ_STATUS[:assigned]}

        update_bug(bz_bug.bz_id, oneway='true', params_bz)

        bz_bug.bz_assignee = assignee_email
        bz_bug.bz_action = BzBug::BZ_ACTIONS[:accepted]
        bz_bug.save
      end
    end
  end

  def upgrade_bz2?(assignee_email, bz_bug)
    bz_bug.summary.match(/Upgrade/) &&
    !assignee_email.nil? &&
    (!bz_bug.component.blank? &&
     bz_bug.component.include?('RPMs')) &&
    (bz_bug.keywords.include? 'Rebase')
  end

  def update_tags(params, package)
    if params[:process_tags] == 'Yes'
      package.tags = process_tags(params[:tags], package.task_id)
    end
  end

  def update_inline_bz(bz_cred, shared_inline_bzs, package)

    shared_bz_user, shared_bz_pass = bz_cred
    package.delete_all_bzs if empty_list(shared_inline_bzs)
    return if shared_inline_bzs.blank? # nothing to do

    Package.transaction do
      require 'set'
      inline_bz_set = Set.new shared_inline_bzs
      all_bz_bugs_set = Set.new package.bz_bug_ids

      deprecated = all_bz_bugs_set - inline_bz_set
      new_bzs = inline_bz_set - all_bz_bugs_set

      bz_queried = []
      error = false

      new_bzs.each do |bz_id|
        bz_query_resp = BzBug.query_bz_bug_info(bz_id, shared_bz_user, shared_bz_pass)
        if bz_query_resp.class == Net::HTTPOK
          bz_queried << JSON.parse(bz_query_resp.body)
        else
          # TODO: find some way to deal with error
          @error_message = "Error: Not Found: bz #{bz_id}"
          error = true
          break
        end
      end

      unless error
        bz_queried.each do |bz_info|
          BzBug.create_from_bz_info(bz_info, package.id, current_user)
        end

        deprecated.each { |bz_bug| package.bz_bug_with_bz_id(bz_bug).destroy }
      end
    end
  end

  def empty_list(str)
    !str.nil? && str.blank?
  end

  def update_params_hash!(params, package)
    params[:package] ||= Hash.new
    params[:package][:id] = package.id

    package_name = params[:package][:name]
    cleanup_pac_name!(params[:package][:name]) unless package_name.blank?

    # set for update_attributes
    params[:package][:created_by] = current_user.id if package.created_by.blank?
    params[:package][:updated_by] = current_user.id
  end

  # shared_inline_bz_val will be a space delimited string containing bugzilla
  # ids
  #
  # e.g '12345 54321 123456'
  #
  # We'll try to transform that string into a list of ints
  # Method returns nil if it the parameter is 'nil' or empty
  #
  # Parameters:
  # +shared_inline_bz_val+: string to break down
  #
  # Returns:
  # nil: if parameter is 'nil' or empty
  # list of ints otherwise
  def get_shared_inline_bz(shared_inline_bz_val)

    shared_inline_bzs = nil

    unless shared_inline_bz_val.blank?
      shared_inline_bzs =
          shared_inline_bz_val.split(/\s+/).map do |bz|
            bz.to_i if bz.to_i > 0
          end
      shared_inline_bzs.compact!
    end
    shared_inline_bzs
  end

  def time_track_package(last_status, last_status_changed, package)
    package.status_changed_at = Time.now

    if !last_status.blank? && last_status.is_time_tracked?
      time_track = TrackTime.all(:conditions => ['package_id=? and status_id=?',
                                                 package.id,
                                                 last_status.id])[0]
      time_track = TrackTime.new if time_track.blank?

      time_track.package_id = package.id
      time_track.status_id = last_status.id
      last_status_changed ||= package.status_changed_at

      time_track.time_consumed ||= 0
      time_track.time_consumed +=
          (package.status_changed_at.to_i - last_status_changed.to_i)/60

      time_track.save
    end
    last_status_changed
  end

  def notify_package_updated(latest_changes, params, package)
    url = get_package_link(params, package).gsub('/edit', '')

    if Setting.activated?(package.task, Setting::ACTIONS[:updated])
      Notify::Package.update(current_user,
                             url,
                             package,
                             Setting.all_recipients_of_package(package,
                                                               current_user,
                                                               :edit),
                             latest_changes)
    end

    unless params[:div_package_edit_notification_area].blank?
      Notify::Package.update(current_user,
                             url,
                             package,
                             params[:div_package_edit_notification_area],
                             latest_changes)
    end
  end

  def destroy
    expire_all_fragments
    @package = Package.find(params[:id])
    @package.updated_by = current_user.id
    @package.set_deleted

    respond_to do |format|
      format.html do
        redirect_to(:controller => :packages,
                    :action => :show,
                    :task_id => escape_url(@package.task.name),
                    :id => escape_url(@package.name))
      end
    end
  end

  def clone
    if request.post?
      Package.transaction do
        source_task = find_task(params[:task_id])
        @source_package = Package.find_by_name_and_task_id(unescape_url(params[:id]), source_task.id)

        @source_package.updated_by = current_user.id
        @source_package.save

        @target_package = @source_package.clone
        target_task = find_task(params[:target_task_name])
        @target_package.task = target_task

        if params[:clone_assignee_option] == 'Yes'
          @target_package.assignee = @source_package.assignee
        end

        if params[:clone_status_option] == 'Yes'
          status_name = @source_package.status.name

          target_status = Status.find_in_global_scope(status_name,
                                                      target_task.name)
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
            target_tag = Tag.find_by_key_and_task_id(source_tag.key,
                                                     target_task.id)
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

      flash[:notice] = 'Clone completed.'

      redirect_to(:controller => :packages,
                  :action => :show,
                  :id => escape_url(@target_package.name),
                  :task_id => escape_url(params[:target_task_name]))
    end
  end

  def get_latest_pkgs_from_brew
    unless params[:secret_key] == 'birdistheword'
      render :status => :unauthorized, :text => 'Wrong secret key' and return
    end
    update_package_brew_nvr(params)
    render :text => params[:task_id]

  end

  def update_package_brew_nvr(params)
    packages = get_packages(unescape_url(params[:task_id]), nil, nil, nil)
    packages.each do |package|
      brew_nvr = package.brew
      if !brew_nvr.nil? && !brew_nvr.empty?
        package.latest_brew_nvr = package.get_brew_name
        package.save
      end
    end
  end

  def export_to_csv

    require 'faster_csv'

    @packages = get_pacs(params)

    @task = find_task(params[:task_id])

    csv_string = FasterCSV.generate do |csv|
      # header row
      header_row = %w(name status tags assignee version bz git_url mead brew)

      csv << header_row

      # data rows
      @packages.each do |package|

        val = [package.name]
        if package.status.blank?
          val << ''
        else
          val << package.status.name
        end

        if package.tags.blank?
          val << ''
        else
          tag_val = ''
          package.tags.each do |tag|
            tag_val << tag.key + ', '
          end
          val << tag_val
        end
        if package.assignee.blank?
          val << ''
        else
          val << package.assignee.email
        end

        val << package.ver
        val << package.bzs_flatten
        val << package.git_url
        val << package.mead
        val << package.brew


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

      package.create_log_entry(start_time, now, current_user)
    end
    respond_to do |format|
      format.js
    end
  end


  def process_mead_info
    @package = Package.find(params[:id])

    @package.update_mead_brew_info

    respond_to do |format|
      format.js {

      }
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
      if @package.tags.blank?
        target_package.tags = nil
        target_package.save
      else
        target_tags = []
        @package.tags.each do |source_tag|
          target_tag = Tag.find_by_key_and_task_id(source_tag.key,
                                                   target_package.task_id)
          if target_tag.blank?
            target_tag = source_tag.clone
            target_tag.task_id = target_package.task_id
            target_tag.save
            target_tags << target_tag
          else
            target_tags << target_tag
          end
        end
        target_package.tags = target_tags
        target_package.save
      end
    end
  end

  def sync_status
    @package.all_relationships_of('clone').each do |target_package|
      # User has unset the status of source package, so we unset all the
      # statuses assigned to target packages.
      if @package.status.blank?
        target_package.status = nil
        target_package.save
      else
        target_status = Status.find_in_global_scope(@package.status.name,
                                                    target_package.task.name)

        if target_status.blank?
          target_status = @package.status.clone
          target_status.task = target_package.task
          target_status.save
          target_package.status = target_status
          target_package.save
        else
          target_package.status = target_status
          target_package.save
        end
      end
    end
  end

  def clone_form_validation
    unless request.post?
      return
    end

    @error_message = []

    target_task = find_task(params[:target_task_name])

    if target_task.blank?
      @error_message << 'Target task not found.'

    else

      if Package.find_by_name_and_task_id(unescape_url(params[:id]), target_task.id)
        @error_message << 'Package already exists in target task.'
      end
    end

    unless @error_message.blank?
      render :controller => 'packages',
             :action => 'clone',
             :id => escape_url(params[:id]),
             :task_id => escape_url(params[:task_id])
    end

  end

  def cleanup_pac_name!(name)
    name.strip! unless name.blank?
  end

  def user_view_index
    if !params[:user].blank? && params[:task_id].blank?
      redirect_to(:controller => :user_views,
                  :action => :index,
                  :user_id => User.find_by_email(params[:user]).name)
    end
  end

  def get_packages(__task_name, __tag_key, __status_name, __user_email)
    order = 'status_id, name'

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
