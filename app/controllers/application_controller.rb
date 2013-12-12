# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  helper_method :escape_url, :unescape_url, :can_manage?, :logged_in?, :has_task?, :count_packages, :can_edit_package?, :current_user, :get_task, :has_status?, :has_tag?, :deleted_style, :can_delete_comment?, :generate_request_path, :is_global?, :current_user_email, :task_has_tags?, :get_xattrs, :background_style, :confirmed?, :default_style
  helper_method :btag, :ebtag, :uebtag, :truncate_u, :its_me?, :extract_username, :has_bz_auth_info?, :has_mead_integration?
  before_filter :process_task_id
  before_filter :save_current_link
              # Scrub sensitive parameters from your log
              # filter_parameter_logging :password
  filter_parameter_logging :bzauth_pwd, :pwd, :ubbs_pwd, :jira_pass

  def get_task(name)
    Task.find_by_name(unescape_url(name))
  end

  def escape_url(url)
    if url.blank?
      nil
    else
      url.gsub(/\./, '-dot-').gsub(/\//, '-slash-')
    end
  end

  def unescape_url(url)
    if url.blank?
      nil
    else
      url.gsub(/-dot-/, '.').gsub(/-slash-/, '/')
    end
  end

  def can_manage?
    logged_in? && session[:current_user].can_manage == 'Yes'
  end

  def logged_in?
    !session[:current_user].blank?
  end

  def has_task?(id = params[:task_id])
    if id.blank?
      false
    else
      if Task.find_by_name(unescape_url(id)).blank?
        false
      else
        true
      end
    end
  end

  def has_status?
    !params[:status].blank?
  end

  def has_tag?
    !params[:tag].blank?
  end

  def can_edit_package?(package)
    _package = Package.find(package.id)
#    _package.revert_to(_package.last_version)
    (logged_in? && _package.user_id == session[:current_user].id) || can_manage?
  end

  def count_packages(bt, status_name)
    bt_quoted = "'#{bt}'"
    global_status = Status.find(:first, :conditions => ["global='Y' AND name=?", status_name])
    status_id = -1
    if global_status == nil
      status_id = Status.find_by_name_and_task_id(status_name, Task.find_by_name(bt).id).id
    else
      status_id = global_status.id
    end

#    children = "union select children.id as id from tasks parent join tasks children on parent.id = children.parent_id and parent.name = #{bt_quoted} "
    hierarchy = "select id from tasks where name = #{bt_quoted}"
    Package.count(:conditions => ["status_id = ? AND task_id IN (#{hierarchy})", status_id])
  end

  def current_user
    session[:current_user]
  end

  def current_user_email
    session[:current_user].email if session[:current_user]
  end

  def deleted_style(package)
    if !package.blank? && package.deleted?
      'text-decoration:line-through;'
    end
    ''
  end

  def can_delete_comment?(comment)
    if logged_in?
      if can_manage?
        return true
      else
        return comment.user_id == current_user.id
      end
    else
      false
    end
  end

  def generate_request_path(request, frag=nil)
    if request.blank?
      return ''
    end

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
    open('/tmp/ett_clone_in_progress_marker', 'a') { |f|
      f.puts e.message
      f.puts e.backtrace.inspect
    }

  end

  def get_xattrs(task = nil, check_show_xattrs = true, check_enable_xattrs = true)
    if task.blank? || !Setting.enabled_in_task?(task) # check the system settings
      if validate_xattr_options(check_show_xattrs, check_enable_xattrs, task)
        Setting.system_settings.xattrs.split(',').each do |attr|
          unless attr.blank?
            yield attr.strip
          end
        end
      end
    else #if the tag has local settings and set to show extended attributes, get all extended attributes name and display here.
      if validate_xattr_options(check_show_xattrs, check_enable_xattrs, task)
        task.setting.xattrs.split(',').each do |attr|
          unless attr.blank?
            yield attr.strip
          end
        end
      end
    end
  end

  def validate_xattr_options(check_show_xattrs, check_enable_xattrs, task)
    if task.blank? || !Setting.enabled_in_task?(task) # check the system settings
      flag = true
      if check_show_xattrs == true
        if Setting.system_settings.show_xattrs?
          flag = true
        else
          flag = false
        end
      else
        flag = true
      end

      if flag == false
        return false
      end

      if check_enable_xattrs == true
        if Setting.system_settings.enable_xattrs?
          flag = true
        else
          flag = false
        end
      else
        flag = true
      end

      flag
    else #if the tag has local settings and set to show extended attributes, get all extended attributes name and display here.
      flag = true
      if check_show_xattrs == true
        if task.setting.show_xattrs?
          flag = true
        else
          flag = false
        end
      else
        flag = true
      end

      if flag == false
        return false
      end

      if check_enable_xattrs == true
        if task.setting.enable_xattrs?
          flag = true
        else
          flag = false
        end
      else
        flag = true
      end

      flag

    end
  end

  def task_clone_done
    task_clone_in_status('done')
  end

  def task_clone_in_status(status)
    File.open('/tmp/ett_clone_in_progress_marker', 'w') { |f| f.write(status) }
  end

  def task_has_tags?(task_name)
    task = Task.find_by_name(task_name)
    if task
      if task.tags.size > 0
        return true
      end
    end

    false
  end


  def truncate_u(text, length = 30, truncate_string = "...")
    return '' if text.blank?
    text = text.dup.strip

    l = 0
    char_array = text.unpack("U*")
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
        return char_array[0..i].pack("U*") + (i < char_array.length - 1 ? truncate_string : "")
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
    unless can_manage?
      home_page
    end
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
    unless logged_in?
      home_page
    end
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
    unless params[:task_id].blank?
      params[:task_id] = escape_url(params[:task_id])
    end
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
    if idx % 2 == 0
      '#fff'
    else
      '#f5f5f5'
    end
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
    if bt.blank?
      nil
    else
      bt.id
    end
  end


  def default_style(css)
    if css.blank?
      "background:#808080;"
    else
      css
    end
  end

  def layout_exist?(layout)
    File.exist?(RAILS_ROOT + "/app/views/layouts/" + layout + ".html.erb")
  end

  def its_me?(user)
    return false unless logged_in?
    return false if user.blank?
    can_manage? || current_user.email == user.email
  end

  def extract_username(email)
    if email.blank?
      ''
    else
      email.split('@')[0]
    end
  end

  def update_bz_pass(pwd)
    if session[:bz_pass].blank? || session[:bz_pass] != pwd
      session[:bz_pass] = pwd
    end
  end

  def bz_bug_creation_uri
    if Rails.env.production?
      return URI.parse(APP_CONFIG['bz_bug_creation_url'])
    else
      return URI.parse(APP_CONFIG['bz_bug_creation_url_mocked'])
    end
  end

  def bz_bug_status_update_url
    if Rails.env.production?
      return APP_CONFIG['bz_bug_status_update_url']
    else
      return APP_CONFIG['bz_bug_status_update_url_mocked']
    end
  end

  # bz_bug_status_update_url: "http:/mead.usersys.redhat.com/mead-bzbridge/bug/status/<id>?oneway=<oneway>&status=<status>&assignee=<assignee>&userid=<userid>&pwd=<pwd>"
  def generate_bug_status_update_url(id, oneway, params)
    link = APP_CONFIG["mead_scheduler"] +
        bz_bug_status_update_url.gsub('<id>', id).gsub('<oneway>', oneway)
    params.each do |key, value|
      link += "&#{key}=#{URI::encode(value)}"
    end
    link
  end

  def generate_bug_summary_update_url(id, oneway, params)
    link = APP_CONFIG["mead_scheduler"] +
        APP_CONFIG["bz_bug_summary_update_url"].gsub('<id>', id).gsub('<oneway>', oneway)
    params.each do |key, value|
      link += "&#{key}=#{URI::encode(value)}"
    end
    link
  end

  def has_bz_auth_info?(params=Hash.new)
    # TODO not complete
    (!current_user.blank? && !session[:bz_pass].blank?) || (!params[:bzauth_user].blank? && !params[:bzauth_pwd].blank?) || (!params[:ubbs_user].blank? && !params[:ubbs_pwd].blank?)
  end

  def get_mead_name(brew_pkg)
    uri = URI.parse(URI.encode(APP_CONFIG["mead_scheduler"] +
                                   "/mead-brewbridge/pkg/wrapped/#{brew_pkg}"))
    res = Net::HTTP.get_response(uri)
    if res.code == "200" && !res.body.include?("ERROR")
      res.body
    else
      nil
    end
  end

  def update_bug(bz_id, oneway, params)
    uri = URI.parse(URI.encode(APP_CONFIG["mead_scheduler"]))
    req = Net::HTTP::Post.new(generate_bug_status_update_url(
                                  bz_id, oneway, params))

    puts generate_bug_status_update_url(bz_id, oneway, params)

    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
    res
  end

  def update_bug_summary(bz_id, oneway, params)
    uri = URI.parse(URI.encode(APP_CONFIG["mead_scheduler"]))
    req = Net::HTTP::Put.new(generate_bug_summary_update_url(
                                  bz_id, oneway, params))
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
    res
  end

  def add_comment_milestone_status_to_bug(bz_id, params)
    req_link = "/mead-bzbridge/bug/#{bz_id}?oneway=false"
    params.each do |key, value|
      req_link += "&#{key}=#{URI::encode(value)}" if value != nil
    end
    uri = URI.parse(URI.encode(APP_CONFIG["mead_scheduler"]))
    req = Net::HTTP::Put.new(req_link)

    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
    puts res.response
  end


  def get_scm_url_brew(pac)
    server = XMLRPC::Client.new('brewhub.devel.redhat.com', '/brewhub', 80)
      if pac.mead.nil?
        return nil
      end
    begin

      param = server.call('getBuild', pac.mead)
      if not param.nil?
        server.call('getTaskRequest', param['task_id'])[0]
      else
        nil
      end
    rescue XMLRPC::FaultException => e
      nil
    end
  end

  def get_brew_name(pac)
    # TODO: make the tag more robust
    tag = pac.task.candidate_tag + '-build'
    uri = URI.parse(URI.encode(APP_CONFIG["mead_scheduler"] +
                                   "/mead-brewbridge/pkg/latest/#{tag}/#{pac.name}"))
    res = Net::HTTP.get_response(uri)
    if res.code == "200" && !res.body.include?("ERROR")
      res.body
    else
      nil
    end
  end

  def extract_bz_bug_info(body)
    #  @response.body
    # "999999: Upgrade jboss-aggregator to 7.2.0.Final-redhat-7 (MOCK)"
    bug_info = Hash.new
    unless body.blank?
      bug_info[:bz_id] = body.scan(/^\d+/)[0].to_i
      bug_info[:summary] = body.split(/^\d+:\s*/)[1]
    end
    bug_info
  end

  def query_bz_bug_info(bz_id, user, pwd)
    uri = URI.parse(URI.encode(APP_CONFIG["mead_scheduler"]))
    req = Net::HTTP::Get.new("/mead-bzbridge/bug/#{bz_id}?userid=#{user}&pwd=#{pwd}")
    req['Accept'] = 'application/json'
    response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end
  end

  def current_bzuser(params)
    extract_username(params[:bzauth_user])
  end

  def current_bzpass(params)
    if session[:bz_pass].blank?
      return params[:bzauth_pwd]
    else
      return session[:bz_pass]
    end
  end

  def get_bz_info(bz_id, userid, pwd)
    @response = query_bz_bug_info(bz_id, user_id, pwd)
    bz_info = nil
    if @response.class == Net::HTTPOK
      bz_info = JSON.parse(@response.body)
    end

    bz_info
  end

  def verify_bz_credentials(params)
    bzauth_user = extract_username(params[:bzauth_user])
    bzauth_pwd = params[:bzauth_pwd]

    if bzauth_user.blank? || bzauth_pwd.blank?
      return 401 # authentication failure
    end

    res = Net::HTTP.get_response(URI("#{APP_CONFIG["bz_bug_check"]}#{bzauth_user}?pwd=#{bzauth_pwd}"))
    res.code
  end


  # mode flag needed since for mode=:create,
  # the request_path link is wrong
  def get_package_link(params, package, mode=:edit)
    hardcoded_string = APP_CONFIG["site_prefix"] +
        "tasks/" + escape_url(@package.task.name) +
        "/packages/" + escape_url(@package.name)

    if mode == :create
      hardcoded_string
    elsif params[:request_path].blank?
      hardcoded_string
    else
      params[:request_path]
    end
  end

  def build_type(package)
    Net::HTTP.get('mead.usersys.redhat.com', "/mead-scheduler/rest/package/eap6/#{package}/type")
  end

  def need_source_url?(package)
    build = build_type(package.name)
    build_check = (build == 'WRAPPER') || (build == "MEAD_ONLY")
    has_wrapper_tag = !(package.tags.select { |tag| tag.key == 'wrapper' }).empty?
    return build_check || has_wrapper_tag
  end

end
