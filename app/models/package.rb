# ==============================================================================
# Seems to be good for Rails4!
# Just need to find an alternative to act_as_textiled
# ==============================================================================
require 'net/http'

class Package < ActiveRecord::Base
  #  STATUS = [ 'Open', 'Assigned', 'Finished', 'Uploaded', 'Deleted' ]
  #  STATUS_FOR_CHOICE = [ 'Assigned', 'Finished', 'Uploaded', 'Deleted' ]
  #  SORTED_STATUS = ['Open', 'Assigned', 'Finished', 'Uploaded', 'Deleted']
  SKIP_FIELDS = %w(id updated_at updated_by created_by created_at)
  MEAD_ACTIONS = {:open => 'open', :needsync => 'needsync', :done => 'done'}

  # info obtained from errata code
  RPMDIFF_INFO = {
      0 => {:status => 'PASSED', :style => 'background-color: #b5f36d;'},
      1 => {:status => 'INFO', :style => 'background-color: #b5f36d;'},
      2 => {:status => 'WAIVED', :style => 'background-color: #b5f36d;'},
      3 => {:status => 'NEEDS INSPECTION', :style => 'background-color: #ff5757;'},
      4 => {:status => 'FAILED', :style => 'background-color: #ff5757;'},
      498 => {:status => 'TEST IN PROGRESS', :style => 'background-color: #b2f4ff;'},
      499 => {:status => 'UNPACKING FILES', :style => 'background-color: #b2f4ff;'},
      500 => {:status => 'QUEUED FOR TEST', :style => 'background-color: #b2f4ff;'},
      -1 => {:status => 'DUPLICATE', :style => 'background-color: #b2ffa1;'}
  }
  if Rails::VERSION::STRING < "4"
    # TODO: fix me in Rails4
    acts_as_textiled :notes
  end
  acts_as_commentable

  belongs_to :user #assignee
  belongs_to :assignee, :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :creator, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :task
  belongs_to :status

  has_many :rpm_diffs, :dependent => :destroy
  has_many :assignments, :dependent => :destroy
  has_many :tags, :through => :assignments
  has_many :bz_bugs, :dependent => :destroy
  has_many :brew_nvrs, :dependent => :destroy

  has_many :to_relationships, :class_name => 'PackageRelationship',
           :foreign_key => 'from_package_id', :dependent => :destroy

  has_many :from_relationships, :class_name => 'PackageRelationship',
           :foreign_key => 'to_package_id', :dependent => :destroy

  has_many :p_attachments, :dependent => :destroy

  has_many :changelogs, :class_name => 'Changelog',
           :foreign_key => 'package_id', :dependent => :destroy

  validates_presence_of :name
  validates_presence_of :task_id
  validates_presence_of :created_by
  validates_presence_of :updated_by

  # provided by default_value_for gem
  default_value_for :time_consumed, 0
  default_value_for :time_point, 0
  default_value_for :status_changed_at, Time.now
  default_value_for :mead_action, MEAD_ACTIONS[:open]
  default_value_for :in_errata, ''
  default_value_for :rpmdiff_status, ''

  ######### This is duplicated from application_controller.rb since some methods
  # are using that method right now. It's here temporarily and will have to be
  # moved to a better place eventually.
  # FIXME ?
  def escape_url(url)
    url.blank? ? nil : url.gsub(/\./, '-dot-').gsub(/\//, '-slash-')
  end

  def unescape_url(url)
    url.blank? ? nil : url.gsub(/-dot-/, '.').gsub(/-slash-/, '/')
  end
  #####################################################################
  #
  @package_sets = nil

  # Return a boolean to indicate whether this package's version column field can
  # be updated
  #
  # If the status of this package is not in the 'Finished' state, then the
  # version can be edited
  #
  # Returns: boolean
  def can_edit_version?
    if status.respond_to?(:code)
      status.code != Status::CODES[:finished]
    else
      true
    end
  end

  def close_github_pr_closed(github_client)

    git_repo = ENV['GITHUB_REPO_LINK']

    begin
      pull_request = github_client.pull_request git_repo, self.github_pr

      if pull_request.state == 'closed'
        # TODO: yeah maybe one day rename that to something more appropriate
        self.github_pr_closed = true
        self.save
      end
    rescue
      "Error in fetching PR #{self.github_pr}"
    end
  end

  def changes_with_old(orig_package)
    diff = orig_package.attributes.diff_custom(self.attributes)
    diff.delete("updated_at") if diff.key?("updated_at")
    diff
  end

  def status_in_finished?
    if status.respond_to?(:code)
      status.code == Status::CODES[:finished]
    else
      false
    end
  end

  # List of users who commented in this package
  #
  # Returns: List of User objects who commented in that package
  def commenters
    comments = Comment.find_by_sql("select distinct user_id from comments "\
                                   "where commentable_type='Package' "\
                                   "and commentable_id=#{id}")
    # return the commenters
    comments.map {|comment| User.find(comment.user_id)}
  end

  def each_attr
    self.attributes.each do |attr|
      yield attr
    end
  end

  # TODO: deprecate this
  def deleted?
    false
  end

  def in_progress?
    !time_point.blank? && time_point > 0
  end

  def github_pr_style
    if self.github_pr.nil? || self.github_pr_closed
      ''
    else
      'background-color: #ff5757;'
    end
  end

  def github_pr_show
    if github_pr_closed == true
      "✔ #{self.github_pr}"
    elsif !self.github_pr.blank?
      "✘ #{self.github_pr}"
    end
  end

  def github_pr_link
    if self.github_pr.blank?
      ""
    else
      "https://github.com/#{ENV["GITHUB_REPO_LINK"]}/pull/#{self.github_pr}"
    end
  end

  def git_url_http_link
    if !self.git_url || !self.git_url.include?("git://git.app.eng.bos.redhat.com")
      ''
    else
      url_link = self.git_url
      repo_link = url_link.split("#")[0]
      commit_id = url_link.split("#")[1]
      repo_name = repo_link.gsub("git://git.app.eng.bos.redhat.com/", '')
      "http://git.app.eng.bos.redhat.com/git/#{repo_name}/commit?id=#{commit_id}"
    end
  end


  def set_deleted
    self.status = Status.deleted_status
    self.save
  end

  def has_the_relationships_of?(relationship_name = nil)
    if relationship_name.blank?
      !self.from_relationships.blank? || !self.to_relationships.blank?
    else
      relationship = Relationship.find_by_name(relationship_name)
      unless relationship.blank?
        if Rails::VERSION::STRING < "4"
          unless PackageRelationship.all(:conditions =>  ['(from_package_id = ? or to_package_id = ?) and relationship_id = ?', self.id, self.id, relationship.id]).blank?
            return true
          end
        else
          unless PackageRelationship.where('(from_package_id = ? or to_package_id = ?) and relationship_id = ?', self.id, self.id, relationship.id).blank?
            return true
          end
        end
      end
      false
    end
  end

  # Return boolean to indicate whether this package can be shipped or not.
  #
  # This is determined by looking at the tags associated with this package. If
  # the tag 'Not Shipped' is present, then this package cannot be shipped
  #
  # Returns: boolean
  def can_be_shipped?
    self.tags.each do |tag|
      if tag.key == 'Not Shipped'
        return false
      end
    end
    true
  end

  def all_relationships_of(relationship_name = nil)
    relationship = Relationship.find_by_name(relationship_name)
    unless relationship.blank?
      packages = []
      packages << all_from_packages_of(self.from_relationships, relationship_name)
      packages << all_to_packages_of(self.to_relationships, relationship_name)
      packages.flatten
    end
  end

  def bzs_flatten
    bz_bugs.map { |bz| bz.bz_id }.join(' ')
  end

  # Find all the bugzillas that qualify as an 'errata bz'
  #
  # Conditions are that the summary must contain 'Upgrade', and the component
  # must be 'RPMs'
  #
  # Returns: List of BzBugs objects
  def upgrade_bz
    self.bz_bugs.select do |bz_bug|
      bz_bug.summary.include?("Upgrade #{self.name}") &&
      bz_bug.component == 'RPMs' &&
      bz_bug.keywords.include?('Rebase')
    end
  end

  # Return the string representation of the object
  #
  # Returns: string
  def to_s
    str = "Name: #{name}\n" \
          "Created By: #{creator.name}(#{creator.email})\n" \
          "Created At: #{created_at}\n" \
          "Belongs To: #{task.name}\n"
    unless assignee.blank?
      str += "Assignee: #{assignee.name}(#{assignee.email})\n"
    end
    str
  end

  # FIXME: not used anywhere, candidate for removal
  def pending_bz_bugs
    if Rails::VERSION::STRING < "4"
      BzBug.all(:conditions => ['package_id = ? and bz_action is not null', self.id])
    else
      BzBug.where('package_id = ? and bz_action is not null', self.id)
    end
  end

  # FIXME: not used anywhere, candidate for removal
  def bz_bug_ids
    # want to return a list of all the ids in the :bz_bugs field
    bz_bugs.map { |bug| bug['bz_id'] }
  end

  # Return string of the brew nvr; append a tick and 'In Errata!' text if the
  # in_errata method returns true
  #
  # e.g 'haha ✔  In Errata!'' # if package 'haha' has in_errata? true
  # e.g 'haha' # if package 'haha' has in_errata? false
  # Returns: string
  def nvr_in_errata
    if in_errata?
      brew + ' ✔  In Errata!'
    else
      brew
    end
  end

  # A variant of nvr_in_errata. Return a string containing a tick and brew nvr
  # if the package is in the errata; a cross and brew_nvr if the package cannot
  # be shipped; just the brew nvr if the above 2 conditions cannot be satisfied
  #
  # Returns: string
  def brew_in_errata(distro)
    brew = self.nvr_in_brew(distro)
    return '✔  ' + brew if in_errata?(distro)
    return '✘  ' + brew if brew && !can_be_shipped?
    return  brew # else
  end

  # Probe the mead scheduler and ask if this package can be shipped or not
  #
  # Returns: boolean
  def in_shipped_list?
    ans = ''
    begin
      Net::HTTP.start('mead.usersys.redhat.com') do |http|
        resp = http.get("/mead-scheduler/rest/package/#{self.task.prod}/#{name}/shipped")
        ans = resp.body
      end
      ans == 'YES'
    rescue
      true
    end
  end

  def in_shipped_database?
    ans = ''
    begin
      Net::HTTP.start('mead.usersys.redhat.com') do |http|
        resp = http.get("/mead-scheduler/rest/package/#{self.task.prod}/#{name}/shipped")
        ans = resp.body
      end
      !ans.include?("NO Package")
    rescue
      false
    end
  end

  def update_tag_if_not_shipped
    if Rails::VERSION::STRING < "4"
      not_shipped_tag = Tag.find(:first,
                                 :conditions => ['key = ? and task_id = ?',
                                                 'Not Shipped', self.task_id])
    else
      not_shipped_tag = Tag.where('key = ? and task_id = ?',
                                  'Not Shipped', self.task_id).first
    end

    if !in_shipped_list? && !not_shipped_tag.nil? && !self.tags.include?(not_shipped_tag)
      if in_shipped_database?
        self.tags << not_shipped_tag
        self.save
      end
    end
  end

  def update_tag_if_native
    if Rails::VERSION::STRING < "4"
      native_tag = Tag.find(:first,
                            :conditions => ['key = ? and task_id = ?',
                            'Native', self.task_id])
    else
      native_tag = Tag.where('key = ? and task_id = ?',
                            'Native', self.task_id).first
    end

    if !native_tag.nil? && !self.tags.include?(native_tag) && self.name.include?('native')
      self.tags << native_tag
      self.save
    end
  end

  # Determines whether this package is already included inside an errata or not.
  #
  # Returns: boolean
  def in_errata?(distro='el6')
      rpmdiff = self.select_rpmdiff(distro)
      if rpmdiff.blank?
        false
      else
        rpmdiff[0].in_errata == 'YES'
      end
  end

  # Return a string representation of the rpmdiff status associated with it.
  #
  # If the rpmdiff_status column is empty, return an empty string instead
  #
  # Returns: string
  def rpmdiff_info(distro)
    rpmdiff = self.select_rpmdiff(distro)
    if rpmdiff.blank? || rpmdiff[0].rpmdiff_status.blank?
      ''
    else
      RPMDIFF_INFO[rpmdiff[0].rpmdiff_status.to_i][:status]
    end
  end

  # Return the errata rpmdiff link associated with this package.
  #
  # If the rpmdiff_id column is empty, return an empty string instead
  #
  # Returns: string
  def rpmdiff_link(distro)
    rpmdiff = self.select_rpmdiff(distro)
    if rpmdiff.blank? || rpmdiff[0].rpmdiff_id.blank?
      ''
    else
      'https://errata.devel.redhat.com/rpmdiff/show/' + rpmdiff[0].rpmdiff_id
    end
  end

  # Return a css color style depending on the current rpmdiff status
  #
  # Returns: string
  def rpmdiff_style(distro)
    rpmdiff = self.select_rpmdiff(distro)
    if rpmdiff.blank? || rpmdiff[0].rpmdiff_status.blank?
      ''
    else
      RPMDIFF_INFO[rpmdiff[0].rpmdiff_status.to_i][:style]
    end
  end

  # Return a css color style depending on the current brew situation
  #
  # If the latest brew nvr information obtained via cron job is not the same as
  # the brew nvr stored in the database, the css color style will be yellow.
  # Otherwise, there will be no css color style
  #
  # Returns: string
  def brew_style
    brew_nvr = self.nvr_in_brew('el6')

    if brew_nvr.nil? || brew_nvr.empty? || latest_brew_nvr.nil? || latest_brew_nvr.empty?
      ''
    elsif brew_nvr == latest_brew_nvr
      ''
    else
      'background-color: yellow;'
    end
  end

  # Return a css color style depending on the current git url
  #
  # If the current git_url is not the same as the git url of the brew build
  # registered in the database when the package is switched to status
  # 'Finished', returns the css color style 'yellow'; otherwise return no style
  #
  # This check will only run if the user can no more edit the version
  # Returns: string
  def get_scm_url_style
    if git_url.blank? || brew_scm_url.blank?
      ''
    elsif (!can_edit_version?) && (git_url.strip != brew_scm_url.strip)
      'background-color: yellow;'
    else
      ''
    end
  end


  # Return a css color style depending on the version column, and the brew and
  # mead nvrs
  #
  # If the value in the version column is also included in the brew, and mead
  # nvrs, then the css style will be nothing.
  #
  # Otherwise, the style will be yellow to tell the user that there is a version
  # mistmatch
  #
  # Returns: string
  def version_style

    if ver.nil? || ver.empty?
      return ''
    end

    # e.g ver = 4.0.19.SP3-redhat-1
    # first_part_ver = 4.0.19
    # second_part_ver = SP3_redhat_1
    first_part_ver = ver.gsub(/\.([^.]*)$/, '').gsub('-', '_')
    second_part_ver = ver.gsub(first_part_ver + '.', '').gsub('-', '_')

    # for alt part, e.g ver = 201103-redhat-3
    # break into two strings at the redhat part
    # alt_first_part = 201103
    # alt_second_part = redhat_3
    # Use alt part only if ver does not contain any dots
    alt_first_part_ver = ver.gsub(/(.)redhat.*/, '').gsub('-', '_')
    alt_second_part_ver = ver.gsub(/#{alt_first_part_ver}(.)/, '').gsub('-', '_')
    [mead, nvr_in_brew('el6')].each do |item|
      if !item.nil? && !item.empty?
        if ver.include?('.')
          unless item.include?(first_part_ver) && item.include?(second_part_ver)
            return 'background-color: #ff5757;'
          end
        else
          unless item.include?(alt_first_part_ver) && item.include?(alt_second_part_ver)
            return 'background-color: #ff5757;'
          end
        end
      end
    end

    # if they are valid, return empty
    ''
  end

  def get_bz_email
    assignee_email = nil

    if assignee.bugzilla_email.blank?
      assignee_email = assignee.email unless assignee.nil?
    else
      assignee_email = assignee.bugzilla_email
    end

    assignee_email
  end

  def generate_bz_comment
    "Source URL: #{git_url}\n" +
    "Mead-Build: #{mead}\n" +
    "Brew-Build: #{self.nvr_in_brew('el6')}\n"
  end

  def select_rpmdiff(distro)
    self.rpm_diffs.select {|rpmdiff| rpmdiff.distro == distro}
  end

  def get_rpmdiff(distro)
    rpmdiffs = self.select_rpmdiff(distro)
    if rpmdiffs.blank?
      rpmdiff = RpmDiff.create
      rpmdiff.package_id = self.id
      rpmdiff.distro = distro
      rpmdiff.save
    else
      rpmdiff = rpmdiffs[0]
    end
    rpmdiff
  end

  def get_brew_rpm_link(nvr, retries = 3)
    server = XMLRPC::Client.new("brewhub.devel.redhat.com", "/brewhub", 80)
    begin
      call = server.call("getBuild", nvr)
      'https://brewweb.devel.redhat.com/taskinfo?taskID=' + call['task_id'].to_s
    rescue Exception => e
      if retries == 0
        nil
      else
        puts "Retrying for nvr '#{nvr}'... attempt #{4 - retries}"
        get_brew_rpm_link(nvr, retries - 1)
      end
    end
  end

  def get_brew_maven_link(nvr)
    server = XMLRPC::Client.new("brewhub.devel.redhat.com", "/brewhub", 80)
    begin
      call = server.call("getMavenBuild", nvr)
      'https://brewweb.devel.redhat.com/buildinfo?buildID=' + call['build_id'].to_s
    rescue Exception => e
      get_brew_rpm_link(nvr)
    end
  end

  def update_mead_information
    if task.use_mead_integration?
      update_mead_brew_info
      update_source_url_info

      self.task.os_advisory_tags.each do |tag|
        brew_nvr =  self.brew_nvrs.select { |obj| obj.distro == tag.os_arch }
        if brew_nvr.blank?
          create_brew_nvr(tag.os_arch)
        else
          brew_nvr = brew_nvr[0]
          brew_nvr.nvr = self.get_brew_name(tag.candidate_tag + '-build', tag.os_arch)
          brew_nvr.link = self.get_brew_rpm_link(brew_nvr.nvr)
          brew_nvr.save
        end
      end
    end
  end

  # TODO: move to a model
  def get_mead_name(brew_pkg)
    uri = URI.parse(URI.encode("#{APP_CONFIG['mead_scheduler']}/mead-brewbridge/pkg/wrapped/#{brew_pkg}"))
    res = Net::HTTP.get_response(uri)

    (res.code == '200' && !res.body.include?('ERROR')) ? res.body : nil
  end

  def sync_tags
    self.all_relationships_of('clone').each do |target_package|
      if self.tags.blank?
        target_package.tags = nil
        target_package.save
      else
        target_tags = []
        self.tags.each do |source_tag|
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
    self.all_relationships_of('clone').each do |target_package|
      # User has unset the status of source package, so we unset all the
      # statuses assigned to target packages.
      if self.status.blank?
        target_package.status = nil
        target_package.save
      else
        target_status = Status.find_in_global_scope(self.status.name,
                                                    target_package.task.name)

        if target_status.blank?
          target_status = self.status.clone
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

  def create_log_entry(start_time, now, current_user)
    log_entry = ManualLogEntry.new
    log_entry.start_time = Time.at(start_time)
    log_entry.end_time = Time.at(now)
    log_entry.who = current_user
    log_entry.package = self
    log_entry.save
  end


  def notify_package_created(params, current_user)
    url = self.get_package_link(params, :create)

    if Setting.activated?(self.task, Setting::ACTIONS[:created])
      Notify::Package.create(current_user,
                             url,
                             self,
                             Setting.all_recipients_of_package(self, nil, :create))
    end

    unless params[:div_package_create_notification_area].blank?
      Notify::Package.create(current_user,
                             url,
                             self,
                             params[:div_package_create_notification_area])
    end
  end

  def notify_package_updated(latest_changes, params, current_user)
    url = self.get_package_link(params).gsub('/edit', '')

    if Setting.activated?(self.task, Setting::ACTIONS[:updated])
      Notify::Package.update(current_user,
                             url,
                             self,
                             Setting.all_recipients_of_package(self,
                                                               current_user,
                                                               :edit),
                             latest_changes)
    end

    unless params[:div_package_edit_notification_area].blank?
      Notify::Package.update(current_user,
                             url,
                             self,
                             params[:div_package_edit_notification_area],
                             latest_changes)
    end
  end

  # mode flag needed since for mode=:create,
  # the request_path link is wrong
  def get_package_link(params, mode=:edit)
    hardcoded_string = "#{APP_CONFIG['site_prefix']}tasks/#{escape_url(self.task.name)}/packages/#{escape_url(self.name)}"

    if mode == :create
      hardcoded_string
    elsif params[:request_path].blank?
      hardcoded_string
    else
      params[:request_path]
    end
  end

  def time_track_package(last_status, last_status_changed)
    self.status_changed_at = Time.now

    if !last_status.blank? && last_status.is_time_tracked?
      if Rails::VERSION::STRING < "4"
        time_track = TrackTime.all(:conditions => ['package_id=? and status_id=?',
                                                   self.id,
                                                   last_status.id])[0]
      else
        time_track = TrackTime.where('package_id=? and status_id=?',
                                     self.id,
                                     last_status.id).take
      end
      time_track = TrackTime.new if time_track.blank?

      time_track.package_id = self.id
      time_track.status_id = last_status.id
      last_status_changed ||= self.status_changed_at

      time_track.time_consumed ||= 0
      time_track.time_consumed +=
          (self.status_changed_at.to_i - last_status_changed.to_i)/60

      time_track.save
    end
    last_status_changed
  end

  def update_log_entry(last_status, last_status_change, current_user)
    log_entry = AutoLogEntry.new

    last_status_change ||= self.status_changed_at
    log_entry.start_time = last_status_change
    log_entry.end_time = self.status_changed_at
    log_entry.who = current_user
    log_entry.package = self
    log_entry.status = last_status

    log_entry.save
  end

  def build_type
    Net::HTTP.get('mead.usersys.redhat.com',
                  "/mead-scheduler/rest/package/#{self.task.prod}/#{self.name}/type")
  end

  # get_mead_info will go get the mead nvr from the rpm repo directly if it
  # cannot find it via the mead scheduler
  def update_mead_brew_info
    brew_pkg = self.get_brew_name
    if brew_pkg.blank?
      uri = URI.parse("http://pkgs.devel.redhat.com/cgit/rpms/#{self.name}/plain/last-mead-build?h=#{self.task.primary_os_advisory_tag.candidate_tag}")
      res = Net::HTTP.get_response(uri)
      # TODO: error handling
      package_old_mead = res.body if res.code == '200'
      package_name = self.parse_nvr(package_old_mead)[:name]

      uri = URI.parse("http://mead.usersys.redhat.com/mead-brewbridge/pkg/latest/#{self.task.primary_os_advisory_tag.candidate_tag}-build/#{package_name}")
      res = Net::HTTP.get_response(uri)
      self.mead = res.body if res.code == '200'
    else
      self.mead = get_mead_name(brew_pkg) unless brew_pkg.blank?
    end

    self.mead_link = self.get_brew_maven_link(self.mead) if self.mead

    self.mead_action = Package::MEAD_ACTIONS[:done]
    self.save
  end

  def deleted_style
    if self.deleted?
      'text-decoration:line-through;'
    else
      ''
    end
  end

  def get_scm_url_brew
    server = XMLRPC::Client.new('brewhub.devel.redhat.com', '/brewhub', 80)

    return nil if mead.nil?

    begin
      param = server.call('getBuild', mead)
      param.nil? ? nil : server.call('getTaskRequest', param['task_id'])[0]
    rescue XMLRPC::FaultException
      nil
    end
  end

  def is_scl_package?
    ans = ''
    begin
      Net::HTTP.start('mead.usersys.redhat.com') do |http|
        resp = http.get("/mead-scheduler/rest/package/#{self.task.prod}/#{name}/scl")
        ans = resp.body
      end
      ans == 'YES'
    rescue
      true
    end
  end

  def get_brew_name(candidate_tag=nil, distro=nil)
    # TODO: make the tag more robust
    tag = candidate_tag.nil? ? "#{task.primary_os_advisory_tag.candidate_tag}-build" : candidate_tag

    # FIXME: stop that hardcoding... one day!
    pkg_name = self.name
    if distro == 'el7' && self.is_scl_package?
      pkg_name = 'eap6-' + pkg_name.sub(/-eap6$/, '')
    end
    uri = URI.parse(URI.encode("#{APP_CONFIG['mead_scheduler']}/mead-brewbridge/pkg/latest/#{tag}/#{pkg_name}"))

    res = Net::HTTP.get_response(uri)

    (res.code == '200' && !res.body.include?('ERROR')) ? res.body : nil
  end

  # based on the brew koji code, move it to package model afterwards
  # error checking omitted
  def parse_nvr(nvr)
    ret = {}
    p2 = nvr.rindex('-')
    p1 = nvr.rindex('-', p2 - 1)
    puts p1
    puts p2
    ret[:release] = nvr[(p2 + 1)..-1]
    ret[:version] = nvr[(p1 + 1)...p2]
    ret[:name] = nvr[0...p1]

    ret
  end

  def update_source_url_info
    self.brew_scm_url = get_scm_url_brew
    self.git_url = self.brew_scm_url
    save
  end

  def duplicate_package_msg
    "Package #{self.name} already exists. Here's the " \
    "<a href='/tasks/#{escape_url(self.task.name)}/packages/#{unescape_url(self.name)}'" \
    " target='_blank'>link</a>."
  end

  def delete_all_bzs
    Package.transaction do
      bz_bugs.each { |bz_bug| bz_bug.destroy }
    end
  end
  # For all bugzillas associated with this package, return the one with bugzilla
  # id bz_id. If nothing is found, return nil.
  #
  # Params:
  # +bz_id+: integer/string -> bz_id to find
  #
  # Returns: BzBug object if found; nil otherwise
  def bz_bug_with_bz_id(bz_id)
    if bz_bugs.blank?
      nil
    else
      bz_bugs.each do |bz_bug|
        if bz_bug.bz_id == bz_id.to_s
          return bz_bug
        end
      end
      nil
    end
  end

  def update_user_id(id)
    self.user_id = id
    save
  end

  def create_brew_nvr(distro)
    adv_tag = self.task.os_advisory_tags.select { |tag| tag.os_arch == distro }
    if !adv_tag.nil? && adv_tag.size > 0
      brew_nvr = BrewNvr.new
      brew_nvr.package_id = self.id
      brew_nvr.distro = distro
      brew_nvr.nvr = self.get_brew_name(adv_tag[0].candidate_tag + '-build', distro)
      brew_nvr.save
      brew_nvr.nvr
    else
      '-'
    end
  end

  def pkg_brew_rpm_link(distro)
    brew_nvr = self.brew_nvrs.select {|obj| obj.distro == distro}

    if brew_nvr.blank?
      nil
    else
      brew_nvr[0].link
    end
  end

  def nvr_in_brew(distro)
    brew_nvr = self.brew_nvrs.select {|obj| obj.distro == distro}
    if brew_nvr.blank?
      if self.status_in_finished?
        create_brew_nvr(distro)
      else
        '-'
      end
    else
      brew_nvr[0].nvr
    end
  end

  def remove_nvr_and_bugs_from_errata
    result = ''
    self.generate_mead_sched_link.each do |link, nvr, advisory|
      uri = URI.parse(URI.encode(APP_CONFIG['mead_scheduler']))
      req = Net::HTTP::Delete.new(link)

      res = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(req)
      end

      # Need to update the error codes when we get word on their values:
      # TODO: huh make it apply for all of them!
      result += case res.code
      when "202"
        "202: Successfully removed nvr #{nvr} from Errata #{advisory} in task #{self.task.name}"
      when "400"
          "400: Bad Request: One of the mandatory paramenters is missing or has an invalid value.\n
          Link used:  #{link} \n
          #{res.body}"
      when "409"
          "409: Rejected, Errata already submitted for this package \n #{res.body}"
      else
          "#{res.code} error! \n
          Link used: #{link} \n
          #{res.body}"
      end
      result += "\n"
    end
    result
  end


  def add_nvr_and_bugs_to_errata

    status_sched = ''

    if self.status.blank? || self.status.name != 'Finished'
      "You can only add to Errata when the build is Finished."
    elsif !self.in_shipped_list?
        "Package not in shipped list. Aborting"
    else
      uri = URI.parse(URI.encode(APP_CONFIG['mead_scheduler']))
      self.generate_mead_sched_link.each do |link, nvr, advisory|

        req = Net::HTTP::Post.new(link)

        res = Net::HTTP.start(uri.host, uri.port) do |http|
          http.request(req)
        end

        # Need to update the error codes when we get word on their values:
        # TODO: huh make it apply for all of them!
        status_sched += case res.code
        when "202"
            "202: Successfully added nvr #{nvr} to Errata #{advisory}"
        when "400"
            "400: Bad Request: One of the mandatory paramenters is missing or has an invalid value.\n
            Link used:  #{link} \n
            #{res.body}"
        when "409"
            "409: Rejected, Errata already submitted for this package \n #{res.body}"
        else
            "#{res.code} error! \n
            Link used: #{link} \n
            #{res.body}"
        end
        status_sched += "\n"
      end
    end
    status_sched
  end

  def generate_mead_sched_link
    bz_struct = {}
    self.upgrade_bz.each do |bz|
      bz_struct[bz.os_arch] = bz.bz_id
    end

    # the errata request is sent to mead-scheduler's rest api:

    links = []
    # TODO: remove those copy-pasted code!
    self.task.os_advisory_tags.each do |os_tag|

      latest_brew_nvr = self.nvr_in_brew(os_tag.os_arch)
      link = "/mead-scheduler/rest/errata/#{self.task.prod}/files?dist=#{os_tag.os_arch}&nvr=#{latest_brew_nvr}&pkg=#{self.name}&version=#{self.task.tag_version}"
      link += '&bugs=' + bz_struct[os_tag.os_arch] if bz_struct.has_key? os_tag.os_arch

      advisory_used = ''
      if self.errata.blank?
        advisory_used = os_tag.advisory
        link +='&erratum=' + os_tag.advisory unless os_tag.advisory.blank?
      else
        advisory_used = self.errata
        link += '&erratum=' + self.errata
      end

      link += '&tag=' + os_tag.target_tag unless os_tag.target_tag.blank?
      links << [link, latest_brew_nvr, advisory_used]
    end
    links
  end

  # TODO: candidate for removal, no one uses it
  def self.package_unique?(package)
    if Rails::VERSION::STRING < "4"
      @package_sets ||= Set.new(Package.all(:select => "name").map {|pkg| pkg.name})
    else
      @package_sets ||= Set.new(Package.select("name").distinct.map {|pkg| pkg.name})
    end
    !@package_sets.include?(package)
  end

  def native?
    self.tags.each do |tag|
      return true if tag.key == 'Native'
    end
    false
  end

  protected

  def all_from_packages_of(from_relationships, relationship_name)
    all_packages_of(from_relationships, relationship_name,
                    :from_package, :from_relationships)
  end

  def all_to_packages_of(to_relationships, relationship_name)
    all_packages_of(to_relationships, relationship_name,
                    :to_package, :to_relationships)
  end

  def all_packages_of(relationships, relationship_name, pac_mtd, pac_rel_mtd)
    packages = []
    relationships.each do |relationship|
      if relationship.relationship.name == relationship_name
        packages << relationship.send(pac_mtd)
        packages << all_packages_of(relationship.send(pac_mtd).send(pac_rel_mtd),
                                         relationship_name,
                                         pac_mtd, pac_rel_mtd)
      end
    end
    packages.flatten.uniq
  end

  # TODO: candidate for removal
  def self.distinct_in_tasks(tasks)
    if Rails::VERSION::STRING < "4"
      Package.all(:select => 'distinct name',
                  :conditions => ['task_id in (?)', Task.tasks_to_ids(tasks)],
                  :order => 'name')
    else
      Package.where("task_id in (?)", Task.tasks_to_ids(tasks)).select('name').distinct.order('name')
    end
  end

  def self.distinct_in_tasks_can_show(tasks)
    task_ids = Task.tasks_to_ids(tasks)
    can_show_status_ids = []
    task_ids.each do |task_id|
      Status.find_all_can_show_by_task_id_in_global_scope(task_id).each do |status|
        can_show_status_ids << status.id
      end
    end
    if Rails::VERSION::STRING < "4"
      Package.all(:select => 'distinct name',
                  :conditions => ['task_id in (?) and (status_id in (?) or status_id is NULL)', task_ids, can_show_status_ids.uniq],
                  :order => 'name')
    else
      Package.where('task_id in (?) and (status_id in (?) or status_id is NULL)', task_ids, can_show_status_ids.uniq).select('name').distinct.order('name')
    end
  end

  def validate
    p = Package.find_by_name_and_task_id(self.name.strip, self.task_id)
    if p && p.id != self.id
      errors.add(:name, ' - Package name cannot be duplicate under one task!')
    end
  end

  def after_create
    Changelog.package_created(self)
  end

  def after_update
    if self.deleted?
      Changelog.package_deleted(self)
    end
  end
end
