# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  helper_method :escape_url, :unescape_url, :can_manage?, :logged_in?, :has_product?, :count_packages, :can_edit_package?, :current_user, :get_product, :has_label?, :has_mark?, :deleted_style, :can_delete_comment?, :generate_request_path, :is_global?, :current_user_email, :product_has_marks?, :get_xattrs, :background_style, :confirmed?, :default_style
  helper_method :btag, :ebtag, :uebtag, :truncate_u, :its_me?, :extract_username
  before_filter :process_product_id
  before_filter :save_current_link
              # Scrub sensitive parameters from your log
              # filter_parameter_logging :password
  def get_product(name)
    Product.find_by_name(unescape_url(name))
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

  def has_product?(id = params[:product_id])
    if id.blank?
      false
    else
      if Product.find_by_name(unescape_url(id)).blank?
        false
      else
        true
      end
    end
  end

  def has_label?
    !params[:label].blank?
  end

  def has_mark?
    !params[:mark].blank?
  end

  def can_edit_package?(package)
    _package = Package.find(package.id)
#    _package.revert_to(_package.last_version)
    (logged_in? && _package.user_id == session[:current_user].id) || can_manage?
  end

  def count_packages(bt, label_name)
    bt_quoted = "'#{bt}'"
    global_label = Label.find(:first, :conditions => ["global='Y' AND name=?", label_name])
    label_id = -1
    if global_label == nil
      label_id = Label.find_by_name_and_product_id(label_name, Product.find_by_name(bt).id).id
    else
      label_id = global_label.id
    end

#    children = "union select children.id as id from products parent join products children on parent.id = children.parent_id and parent.name = #{bt_quoted} "
    hierarchy = "select id from products where name = #{bt_quoted}"
    Package.count(:conditions => ["label_id = ? AND product_id IN (#{hierarchy})", label_id])
  end

  def current_user
    session[:current_user]
  end

  def current_user_email
    session[:current_user].email if session[:current_user]
  end

  def deleted_style(package)
    if package.deleted?
      'text-decoration:line-through;'
    end
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

  def mark_clone_in_progress
    mark_clone_in_status('in_progress')
  end

  def mark_clone_failed(e)
    mark_clone_in_status('failed')
    open('/tmp/ett_clone_in_progress_marker', 'a') { |f|
      f.puts e.message
      f.puts e.backtrace.inspect
    }

  end

  def get_xattrs(product = nil, check_show_xattrs = true, check_enable_xattrs = true)
    if product.blank? || !Setting.enabled_in_product?(product) # check the system settings
      if validate_xattr_options(check_show_xattrs, check_enable_xattrs, product)
        Setting.system_settings.xattrs.split(',').each do |attr|
          unless attr.blank?
            yield attr.strip
          end
        end
      end
    else #if the tag has local settings and set to show extended attributes, get all extended attributes name and display here.
      if validate_xattr_options(check_show_xattrs, check_enable_xattrs, product)
        product.setting.xattrs.split(',').each do |attr|
          unless attr.blank?
            yield attr.strip
          end
        end
      end
    end
  end

  def validate_xattr_options(check_show_xattrs, check_enable_xattrs, product)
    if product.blank? || !Setting.enabled_in_product?(product) # check the system settings
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
        if product.setting.show_xattrs?
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
        if product.setting.enable_xattrs?
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

  def mark_clone_done
    mark_clone_in_status('done')
  end

  def mark_clone_in_status(status)
    File.open('/tmp/ett_clone_in_progress_marker', 'w') { |f| f.write(status) }
  end

  def product_has_marks?(product_name)
    product = Product.find_by_name(product_name)
    if product
      if product.marks.size > 0
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

  def check_product
    unless has_product?
      flash[:notice] = 'Tag must be specified.'
      home_page
    end
  end

  def check_product_or_user
    if !has_product? && params[:user].blank?
      flash[:notice] = 'User or Tag must be specified.'
      home_page
    end
  end

  def is_global?(label)
    label.global == 'Y'
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

  def process_marks(mark_keys, product_id)
    mark_keys ||= []
    new_marks = []

    mark_keys.each do |key|
      mark = Mark.find_by_key_and_product_id(key, product_id)
      new_marks << mark
    end
    new_marks
  end

  def home_page
    #unless has_product?
    #  unless Setting.system_settings.default_product.blank?
    #    default_product = Product.find_by_name(Setting.system_settings.default_tag)
    #    unless default_product.blank?
    #      params[:product_id] = escape_url(default_product.name)
    #    else
    #      params[:product_id] = escape_url(Product.find(:first, :order => 'updated_at DESC').name)
    #    end
    #  else
    #    params[:product_id] = escape_url(Product.find(:first, :order => 'updated_at DESC').name)
    #  end
    #end

    redirect_to(:controller => :packages, :action => :index)

  end

  def process_product_id
    unless params[:product_id].blank?
      params[:product_id] = escape_url(params[:product_id])
    end
  end

  def save_current_link
    unless request.path =~ /login|logout|users|sessions|session/
      session[:prev_url] = generate_request_path(request)
    end
  end


  #def notify_package_update_system_wide(link, package)
  #  if Setting.system_settings.actions & Setting::ACTIONS[:updated] > 0
  #    notify_package_update(link, package, Setting.all_recipients_of_package(@package))
  #  end
  #end

  def expire_all_fragments
    expire_fragment(%r{products/.*})
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
    params[:product_id]
  end

  def ebtag
    escape_url(params[:product_id])
  end

  def uebtag
    unescape_url(params[:product_id])
  end

  def btagid
    bt = Product.find_by_name(uebtag)
    if bt.blank?
      nil
    else
      bt.id
    end
  end

  def default_style(css)
    if css.blank?
      return "background:#808080;"
    else
      return css
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
end
