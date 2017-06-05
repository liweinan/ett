class PackagesController < ApplicationController
  include ApplicationHelper
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
      @title = unescape_url(params[:task_id])
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

      format.json { render :json => @packages }

    end
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
    if params.include?(:assignee)
      @package.assignee = User.find(params[:assignee])
    end
    redirect_to('/') unless logged_in?
  end

  # POST /packages
  # POST /packages.xml
  def create

    @package = Package.new(params[:package])
    cleanup_pac_name!(@package.name)

    @package.created_by = current_user.id
    @package.updated_by = current_user.id

    @package.tags = process_tags(params[:tags], params[:package][:task_id])

    @package.update_tag_if_native
    @package.update_tag_if_not_shipped

    failed_admin_con = false
    # conditions if user is not admin
    unless can_manage?
      unless @package.task.allow_non_existent_pkgs
        if Package.package_unique?(@package.name)
          failed_admin_con = true
          flash[:notice] = 'Package is new to ETT. You do not have permission to add new packages already in ETT for this task.'
        end
      end

      unless @package.task.allow_non_shipped_pkgs
        unless @package.can_be_shipped?
          failed_admin_con = true
          flash[:notice] = 'You do not have permission to add non-shipped packages for this task.'
        end
      end
    end


    respond_to do |format|
      if !failed_admin_con && @package.save
        expire_all_fragments
        flash[:notice] = 'Package was successfully created.'

        if Rails.env.production?
          @package.notify_package_created(params, current_user)
        end

        format.html { show_package(params, @package) }
      else
        @user = params[:user]
        format.html { render :action => :new }
      end
    end
  end

  # PUT /packages/1
  # PUT /packages/1.xml
  # params[:flatten_bzs] seems to be only used for inline bugzilla
  # params[:process_tags] ??
  def update
    # for Changelog.package_updated
    orig_package = Package.find(params[:id])
    @package = Package.find(params[:id])
    expire_fragment(@package)
    shared_inline_bzs = nil
    if @package.task.use_bz_integration?
      update_bz_pass(params[:bzauth_pwd])
      bz_cred = bz_user_pass(params, session)

      unless params[:flatten_bzs].blank?
        shared_inline_bzs = get_shared_inline_bz(params[:flatten_bzs])
        update_inline_bz(bz_cred, shared_inline_bzs, @package)
      end
    end

    update_params_hash!(params, @package)

    old_values = orig_package.old_package_values

    respond_to do |format|
      Package.transaction do
        # if update_inline_bz is true, then it’s a pure update bzs request in inline editor.
        # So package edit page won’t bypass all the actions in below because update_inline_bz
        # will always be blank then.
        if shared_inline_bzs.blank?
          # this is when everything is saved
          @package.update_attributes(params[:package])
          @package.update_ini_scmurl
          @package.reload
          # this is needed since we write to @package later in this section of
          # the code. (@package.status_changed_at = Time.now). This messes up
          # with the latest_changes command since the latest_change will be that
          # instead of what the user changed in the website.
          latest_changes_package = @package.changes_with_old(orig_package)

          update_tags(params, @package)

          if @package.task.use_mead_integration? && @package.status && @package.status.status_in_finished
            @package.update_mead_information
          end

          if @package.task.use_bz_integration?
            update_bzs(old_values, bz_cred, @package)
          end

          if Rails.env.production?
            update_time_track_and_log_entry(old_values, @package)
          end

          if old_values[:github_pr] != @package.github_pr
            @package.github_pr_closed = false
          end

          if @package.status && @package.status.status_in_finished
            @package.milestone = @package.task.milestone
            @package.spec_file = @package.maven_build_arguments = @package.ini_file = nil
          end

          @package.update_tag_if_not_shipped
          @package.update_tag_if_native

          @package.save

          if Rails.env.production?
            @package.update_changelog(orig_package)
            do_sync(%w(name notes ver assignee brew_link group_id artifact_id project_name project_url license scm))
            sync_actions(params, @package)
          end

          flash[:notice] = 'Package was successfully updated.'

          if Rails.env.production?
            @package.notify_package_updated(latest_changes_package, params, current_user)
          end

          @output = true
        else
          unless @package.errors[:name].blank?
            @error_message = @package.duplicate_package_msg
          end
          @user = params[:user]
          @output = false
        end
      end

      if @output
        format.html { show_package(params, @package) }
        format.js
      else
        format.html { render :action => :edit }
        format.js
      end
    end
  end

  # POST /packages/<package>/start-build
  # Parameters:
  # - token (required: str)
  # - clentry (required: str, should start with '- ')
  # - version (optional: str)
  # - scm_url (optional: str)
  # - wrapper_only (optional: bool)
  def start_build
    token = params[:token]
    if token.blank?
      respond_to do |format|
        format.html { render :action => :edit }
        format.json { render :json => {:msg => "Token not provided!"}, :status => 400 }
      end
      return
    end

    clentry = params[:clentry]
    if clentry.blank?
      respond_to do |format|
        format.json { render :json => {:msg => "Clentry not provided!"}, :status => 400 }
      end
      return
    end

    user = User.find_by_token(token)
    if user.blank?
      respond_to do |format|
        format.json { render :json => {:msg => "User not found with this token"}, :status => 400 }
      end
      return
    end

    task = find_task(params[:task])
    if task.blank?
      respond_to do |format|
        format.json { render :json => {:msg => "Task not found!"}, :status => 400 }
      end
      return
    end
    error_msg = ''
    if task.frozen_state?
      error_msg = "Task is frozen! Cannot perform builds"
    end

    if task.readonly?
      error_msg = "Task is read only! Cannot perform builds"
    end

    unless error_msg.blank?
      respond_to do |format|
        format.json { render :json => {:msg => error_msg}, :status => 400 }
      end
      return
    end

    @package = Package.find_by_name_and_task_id(unescape_url(params[:package]),
                                                find_task(params[:task]).id)

    if @package.blank?
      respond_to do |format|
        format.json { render :json => {:msg => "Package not found"}, :status => 404 }
      end
      return
    end

    if params[:version]
      @package.ver = params[:version]
    end

    if params[:scm_url]
      @package.git_url = params[:scm_url]
      @package.update_ini_scmurl
    end
    @package.save

    distros_to_build = []

    @package.task.os_advisory_tags.each do |tag|
      distros_to_build << tag.os_arch
    end
    distros_to_build_str = distros_to_build.join(',')

    type_of_pac = MeadSchedulerService.build_type(@package.task.prod, @package.name)

    regular_rpm_type = ["NON_WRAPPER", "REPOLIB_SOURCE", "NATIVE", "JBOSS_AS_WRAPPER", "JBOSSAS_WRAPPER"]
    chain_type = ["WRAPPER", "WRAPPER_SOURCE"]
    repolib_wrapper_type = ["REPOLIB_WRAPPER", "WRAPPER_ONLY"]
    mead_only_type = ["MEAD_ONLY"]
    container_type = ["CONTAINER"]
    windows_type = ["WINDOWS"]
    type_build = 'chain'
    type_build = 'wrapper' if params[:wrapper_only]

    type_build = 'wrapper' if repolib_wrapper_type.include?(type_of_pac)

    type_build = 'container' if container_type.include?(type_of_pac)
    type_build = 'windows' if windows_type.include?(type_of_pac)
    type_build = 'windows' if distros_to_build.include?("win")

    in_progress_status = Status.find(:first, :conditions => {"statuses.code" => "inprogress", "statuses.global" => "Y"})
    @package.status = in_progress_status
    @package.save
    # Start build here
    result = submit_build(@package, clentry, @package.task.prod, type_build,
                          false, false, distros_to_build_str, user)

    # return 202
    respond_to do |format|
      # If submit successful, return 202
      if result.start_with?("Success")
        status = 202
      else
        # return 400, witch content of error
        status = 400
      end
      format.json { render :json => {:msg => result}, :status => status }
    end
  end

  def refresh_nvr_information
    package = Package.find(params[:id])
    package.update_mead_information
    show_package(params, package)
  end


  def update_changelog(orig_package, package)
    orig_tags = orig_package.tags.clone
    Changelog.package_updated(orig_package, package, orig_tags)
  end

  def get_pacs(params)
    get_packages(unescape_url(params[:task_id]),
                 unescape_url(params[:tag]),
                 unescape_url(params[:status]),
                 unescape_url(params[:user]))
  end


  def show_package(params, package)
    redirect_to(:controller => :packages,
                :action => :show,
                :id => escape_url(package.name),
                :task_id => escape_url(package.task.name),
                :user => params[:user])
  end

  # list of 2 elements, first element is bz_user, and second element is
  # bz_password
  def bz_user_pass(params, session)
    [extract_username(params[:bzauth_user]), session[:bz_pass]]
  end


  def sync_actions(params, package)
    package.sync_status if params[:sync_status] == 'yes'
    package.sync_tags if params[:sync_tags] == 'yes'
  end

  def update_time_track_and_log_entry(old_values, package)
    old_status = old_values[:old_status]
    last_status_changed = old_values[:last_status_changed]

    if package.status != old_status
      last_status_changed = package.time_track_package(old_status,
                                                       last_status_changed)
      package.update_log_entry(old_status, last_status_changed, current_user)
    end
  end

  def update_bzs(old_values, bz_cred, package)

    shared_bz_user, shared_bz_pass = bz_cred
    if Rails.env.production?
      package.upgrade_bz.each do |bz_bug|
        params_bz = {}
        if old_values[:old_assignee] != package.assignee
          params_bz[:assignee] = package.get_bz_email unless package.assignee.nil?
        end

        if version_changed(package.ver, old_values[:old_ver])
          params_bz[:summary] = bz_bug.summary.gsub(old_values[:old_ver],
                                                    package.ver)
        end

        if package.status != old_values[:old_status]
          params_bz.merge!(update_bz_status(package, bz_bug))
        end


        unless params_bz.blank?
          params_bz[:userid] = shared_bz_user
          params_bz[:pwd] = shared_bz_pass

          MeadSchedulerService.set_bz_upstream_fields(bz_bug.bz_id, oneway='true', params_bz)

          bz_bug.bz_action = BzBug::BZ_ACTIONS[:accepted]
          bz_bug.save
        end
      end
    end
  end

  def update_bz_status(package, bz_bug)
    new_status = package.status
    return {} if new_status.blank?
    return {} if package.assignee.blank?
    puts 'Passed first'
    case
      when new_status.status_in_progress
        update_bz_status_progress
      when new_status.status_in_finished
        update_bz_status_finished(package, bz_bug)
      else
        {}
    end
  end

  def update_bz_status_finished(package, bz_bug)
    params_bz = {:milestone => package.task.milestone,
                 :status => BzBug::BZ_STATUS[:modified]}

    if bz_bug.summary.match(/RHEL6/)
      params_bz[:comment] = package.generate_bz_comment
    end

    params_bz
  end

  def update_bz_status_progress
    {:status => BzBug::BZ_STATUS[:assigned]}
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

  def update_tags(params, package)
    if params[:process_tags] == 'Yes'
      package.tags = process_tags(params[:tags], package.task_id)
      package.save
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
        bz_query_resp = MeadSchedulerService.query_bz_bug_info(bz_id, shared_bz_user, shared_bz_pass)
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

  def empty_list(lst)
    !lst.nil? && lst.blank?
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
    update_package_brew_nvr
    render :text => params[:task_id]

  end

  def update_package_brew_nvr
    active_tasks = Task.all(:conditions => ['active = ?', '1'])
    active_tasks.each do |task|
      task.packages.each do |package|
        brew_nvr = package.brew
        if !brew_nvr.blank? &&
           !package.status.nil? &&
           package.status.name == "Finished"
          begin # can throw an error in mead-scheduler is down
            package.latest_brew_nvr = package.get_brew_name
            package.save
          rescue
            puts "ERROR: mead-scheduler might be down"
          end
        end
      end
    end
  end

  def reports
    @packages = get_pacs(params)
    @task = find_task(params[:task_id])
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

        main_distro = package.task.distros[0]

        val << package.ver
        val << package.bzs_flatten
        val << package.git_url
        val << package.mead
        val << package.nvr_in_brew(main_distro)


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

  def get_packages(task_name, tag_key, status_name, user_email)

    task = Task.find_by_name(task_name)
    statuses_string = Status.ids_can_show_by_task_name_in_global_scope(task_name)
    statuses_int = statuses_string.split(',').map {|str| str.to_i}
    statuses_can_show_sql = {:status_id => statuses_int + [nil]}

    condition = {:task_id => task.id}.merge(statuses_can_show_sql)

    @all_packages_count = Package.count(:conditions => condition)
    @my_packages_count = Package.count(:conditions => condition.merge({:user_id => session[:current_user].id})) if logged_in?

    opts = {:user_id => User.find_by_email(user_email).id} unless user_email.blank?
    opts ||= {}
    opts.merge(statuses_can_show_sql)

    order = 'status_id, name'
    includes = [:rpm_diffs, :brew_nvrs, :bz_bugs, :status, :tags, :task]
    if !status_name.blank? && !tag_key.blank?
      tag = Tag.find_by_key_and_task_id(tag_key, task.id)
      status = Status.find_in_global_scope(status_name, task_name)

      conditions = {'assignments.tag_id' => tag.id,
                    'packages.status_id' => status.id,
                    'packages.task_id' => task.id}.merge(opts)

      packages = Package.find(:all, :joins => [:assignments],
                              :conditions => conditions,
                              :order => order,
                              :include => includes)
    elsif !status_name.blank?

      status = Status.find_in_global_scope(status_name, task_name)
      conditions = {'packages.status_id' => status.id,
                    'packages.task_id' => task.id}.merge(opts)
      packages = Package.find(:all, :conditions => conditions,
                              :order => order, :include => includes)
    elsif !tag_key.blank?
      tag = Tag.find_by_key_and_task_id(tag_key, task.id)
      conditions = {'assignments.tag_id' => tag.id,
                    'packages.task_id' => task.id}.merge(opts)
      packages = Package.find(:all, :joins => [:assignments],
                              :conditions => conditions,
                              :order => order, :include => includes)
    else
      conditions = {'packages.task_id' => task.id}.merge(opts)
      packages = Package.find(:all, :conditions => conditions, :order => order,
                              :include => includes)
    end
    packages
  end

  def deal_with_deprecated_brew_tag_id
    unless params[:brew_tag_id].blank?
      params[:task_id] = params[:brew_tag_id]
    end
  end
end
