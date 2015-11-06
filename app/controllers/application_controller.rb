# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  # include all helpers, all the time
  helper :all

  # See ActionController::RequestForgeryProtection for details
  protect_from_forgery

  helper_method :escape_url, :unescape_url, :can_manage?, :logged_in?,
                :has_task?, :count_packages, :can_edit_package?, :current_user,
                :get_task, :has_status?, :has_tag?,
                :can_delete_comment?, :generate_request_path, :is_global?,
                :current_user_email, :task_has_tags?, :get_xattrs,
                :background_style, :confirmed?, :default_style,
                :find_task

  helper_method :btag, :ebtag, :uebtag, :truncate_u, :its_myself?,
                :extract_username, :has_bz_auth_info?

  before_filter :process_task_id
  before_filter :save_current_link

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  filter_parameter_logging :bzauth_pwd, :pwd, :ubbs_pwd, :jira_pass

  def get_task(name)
    Task.find_by_name(unescape_url(name))
  end

  def escape_url(url)
    url.blank? ? nil : url.gsub(/\./, '-dot-').gsub(/\//, '-slash-')
  end

  def unescape_url(url)
    url.blank? ? nil : url.gsub(/-dot-/, '.').gsub(/-slash-/, '/')
  end

  def can_manage?
    logged_in? && session[:current_user].can_manage == 'Yes'
  end

  def logged_in?
    !session[:current_user].blank?
  end

  def has_task?(id = params[:task_id])
    return false if id.blank?
    Task.find_by_name(unescape_url(id)).blank? ? false : true
  end

  def has_status?
    !params[:status].blank?
  end

  def has_tag?
    !params[:tag].blank?
  end

  def can_edit_package?(package)
    logged_in_and_owner_package(package) || can_manage?
  end

  def logged_in_and_owner_package(_package)
    logged_in? && _package.user_id == session[:current_user].id
  end

  def count_packages(bt, status_name)
    bt_quoted = "'#{bt}'"
    global_status = Status.find(:first,
                                :conditions => ["global='Y' AND name=?",
                                                status_name])
    if global_status.nil?
      status_id = Status.find_by_name_and_task_id(status_name,
                                                  Task.find_by_name(bt).id).id
    else
      status_id = global_status.id
    end

    hierarchy = "select id from tasks where name = #{bt_quoted}"
    Package.count(:conditions => ["status_id = ? AND task_id IN (#{hierarchy})",
                                  status_id])
  end

  def current_user
    session[:current_user]
  end

  def current_user_email
    session[:current_user].email if session[:current_user]
  end

  def can_delete_comment?(comment)
    return false unless logged_in?
    can_manage? ? true : comment.user_id == current_user.id
  end

  def generate_request_path(request, frag=nil)
    return '' if request.blank?

    if request.port != 80
      if frag.blank?
        "http://#{request.host}:#{request.port}#{request.path}"
      else
        "http://#{request.host}:#{request.port}/#{frag}"
      end
    else
      if frag.blank?
        "http://#{request.host}#{request.path}"
      else
        "http://#{request.host}/#{frag}"
      end
    end
  end

  def clone_is_done
    clone_is_in_status('done')
  end

  def clone_is_failed
    clone_is_in_status('failed')
  end

  def clone_is_in_status(status)
    File.open('/tmp/ett_clone_in_progress_marker').first.match(/^#{status}/)
  end

  def task_clone_in_progress
    task_clone_in_status('in_progress')
  end

  def task_clone_failed(e)
    task_clone_in_status('failed')
    open('/tmp/ett_clone_in_progress_marker', 'a') do |f|
      f.puts e.message
      f.puts e.backtrace.inspect
    end
  end

  def task_clone_done
    task_clone_in_status('done')
  end

  def task_clone_in_status(status)
    File.open('/tmp/ett_clone_in_progress_marker', 'w') { |f| f.write(status) }
  end

  def get_xattrs(task = nil, check_show_xattrs = true, check_enable_xattrs = true)

    if task_empty_or_setting_not_enabled(task)
      attributes = Setting.system_settings.xattrs
    else
      attributes = task.setting.xattrs
    end

    if validate_xattr_options(check_show_xattrs, check_enable_xattrs, task)
      attributes.split(',').each { |attr| yield attr.strip unless attr.blank? }
    end
  end

  def validate_xattr_options(check_show_xattrs, check_enable_xattrs, task)
    if task_empty_or_setting_not_enabled(task)
      return false unless check_xattrs(check_show_xattrs,
                                       Setting.system_settings.show_xattrs?)

      check_xattrs(check_enable_xattrs, Setting.system_settings.enable_xattrs?)
    else
      # if the tag has local settings and set to show extended attributes,
      # get all extended attributes name and display here.
      return false unless check_xattrs(check_show_xattrs,
                                       task.setting.show_xattrs?)

      check_xattrs(check_enable_xattrs, task.setting.enable_xattrs?)
    end
  end

  def task_empty_or_setting_not_enabled(task)
    task.blank? || !Setting.enabled_in_task?(task)
  end

  def check_xattrs(check_show_xattrs, show_xattrs)
    if check_show_xattrs
      show_xattrs ? true : false
    else
      true
    end
  end

  def task_has_tags?(task_name)
    task = Task.find_by_name(task_name)
    (task && task.tags.size > 0) ? true : false
  end

  def truncate_u(text, length = 30, truncate_string = '...')
    return '' if text.blank?
    text = text.dup.strip

    l = 0
    char_array = text.unpack('U*')
    # 32 and 12288 are spaces
    char_array.delete_if { |c| [10, 13].include?(c) } # delete returns
    char_array.each_with_index do |c, i|
      if c < 127
        l = l + 0.5
        # For english words. We need to check whether we reach the end or not.
        # We should truncate a whole word. If we reach the limit, and the word
        # has left alphas to show, we rollback this word and mark 'l' as already
        # reach limit
        if l >= length && char_array.size > i+1 && ![32, 12288].include?(char_array[i+1]) # word not end naturally
          j = i; # start rollback from current position
          while j >= 0
            j = j - 1
            if [32, 12288].include?(char_array[j]) # match space
              i = j-1 # mark rollback position
              l = length # mark as reach limit
              break
            end
          end
        end
      else
        l = l + 1
      end

      if l >= length
        return char_array[0..i].pack('U*') + (i < char_array.length - 1 ? truncate_string : '')
      end
    end
    text
  end

  protected

  def create_clone_relationship(source_package, target_package)
    pr = PackageRelationship.new
    pr.from_package = source_package
    pr.to_package = target_package
    pr.relationship = Relationship.clone_relationship
    pr.save
  end

  def check_can_manage
    home_page unless can_manage?
  end

  def check_task
    unless has_task?
      flash[:notice] = 'Tag must be specified.'
      home_page
    end
  end

  def check_task_or_user
    if !has_task? && params[:user].blank?
      flash[:notice] = 'User or Tag must be specified.'
      home_page
    end
  end

  def is_global?(status)
    status.global == 'Y'
  end

  def check_user_id
    if params[:user_id].blank?
      flash[:notice] = 'User must be specified.'
      home_page
    end
  end

  def redirect_back_or_default(url)
    if session[:prev_url].blank?
      redirect_to(url)
    else
      prev_url = session[:prev_url].clone
      session[:prev_url] = nil
      redirect_to(prev_url)
    end
  end

  def check_logged_in
    home_page unless logged_in?
  end

  def process_tags(tag_keys, task_id)
    tag_keys ||= []
    new_tags = []

    tag_keys.each do |key|
      tag = Tag.find_by_key_and_task_id(key, task_id)
      new_tags << tag
    end
    new_tags
  end

  def home_page
    redirect_to(:controller => :packages, :action => :index)
  end

  def process_task_id
    params[:task_id] = escape_url(params[:task_id]) unless params[:task_id].blank?
  end

  def save_current_link
    unless request.path =~ /login|logout|users|sessions|session/
      session[:prev_url] = generate_request_path(request)
    end
  end

  def expire_all_fragments
    expire_fragment(%r{tasks/.*})
    expire_fragment(%r{components/.*})
    expire_fragment(%r{packages/.*})
  end

  def background_style(idx)
    (idx % 2 == 0) ? '#fff' : '#f5f5f5'
  end

  def confirmed?
    params[:confirmed] == 'Yes'
  end

  def btag
    params[:task_id]
  end

  def ebtag
    escape_url(params[:task_id])
  end

  def uebtag
    unescape_url(params[:task_id])
  end

  def btagid
    bt = Task.find_by_name(uebtag)
    bt.blank? ? nil : bt.id
  end


  def default_style(css)
    css.blank? ? 'background:#808080;' : css
  end

  def layout_exist?(layout)
    File.exist?("#{RAILS_ROOT}/app/views/layouts/#{layout}.html.erb")
  end

  def find_task(name)
    Task.find_by_name(unescape_url(name))
  end

  def its_myself?(user)
    return false unless logged_in?
    return false if user.blank?
    current_user.email == user.email
  end

  def extract_username(email)
    email.blank? ? '' : email.split('@')[0]
  end

  def update_bz_pass(pwd)
    session[:bz_pass] = pwd if session[:bz_pass].blank? || session[:bz_pass] != pwd
  end

  def has_bz_auth_info?(params=Hash.new)
    # TODO not complete
    (!current_user.blank? && !session[:bz_pass].blank?) ||
    (!params[:bzauth_user].blank? && !params[:bzauth_pwd].blank?) ||
    (!params[:ubbs_user].blank? && !params[:ubbs_pwd].blank?)
  end

  def current_bzuser(params)
    extract_username(params[:bzauth_user])
  end

  def current_bzpass(params)
    session[:bz_pass].blank? ? params[:bzauth_pwd] : session[:bz_pass]
  end

  def get_bz_info(bz_id, user_id, pwd)
    @response = MeadSchedulerService.query_bz_bug_info(bz_id, user_id, pwd)

    bz_info = nil
    bz_info = JSON.parse(@response.body) if @response.class == Net::HTTPOK

    bz_info
  end

  def verify_bz_credentials(params)
    bzauth_user = extract_username(params[:bzauth_user])
    bzauth_pwd = params[:bzauth_pwd]

    return 401 if bzauth_user.blank? || bzauth_pwd.blank?

    res = Net::HTTP.get_response(URI(URI.escape("#{APP_CONFIG['bz_bug_check']}#{bzauth_user}?pwd=#{bzauth_pwd}")))
    res.code
  end
end