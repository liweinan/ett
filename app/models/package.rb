require 'net/http'

class Package < ActiveRecord::Base
  versioned # versioned plugin sucks, try to withdrawal the usage of it.
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
  acts_as_textiled :notes
  acts_as_commentable

  belongs_to :user #assignee
  belongs_to :assignee, :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :creator, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :task
  belongs_to :status

  has_many :assignments, :dependent => :destroy
  has_many :tags, :through => :assignments
  has_many :bz_bugs, :class_name => 'BzBug',
           :foreign_key => 'package_id', :order => 'created_at'

  #has_and_belongs_to_many :components

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

  default_value_for :time_consumed, 0
  default_value_for :time_point, 0
  default_value_for :status_changed_at, Time.now
  default_value_for :mead_action, MEAD_ACTIONS[:open]
  default_value_for :in_errata, ''
  default_value_for :rpmdiff_status, ''

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
        unless PackageRelationship.all(:conditions =>  ['(from_package_id = ? or to_package_id = ?) and relationship_id = ?', self.id, self.id, relationship.id]).blank?
          return true
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
    BzBug.all(:conditions =>
                  ['package_id = ? and summary like ? and component = ?',
                    self.id,
                    "%Upgrade%#{self.name}%",
                    'RPMs'])
  end

  # Return the string representation of the object
  #
  # Returns: string
  def to_s
    str = "Name: #{name}\n"
    str += "Created By: #{creator.name}(#{creator.email})\n"
    str += "Created At: #{created_at.to_s}\n"
    str += "Belongs To: #{task.name}\n"
    unless assignee.blank?
      str += "Assignee: #{assignee.name}(#{assignee.email})\n"
    end
    str
  end

  # FIXME: not used anywhere, candidate for removal
  def pending_bz_bugs
    BzBug.all(:conditions => ['package_id = ? and bz_action is not null', self.id])
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
  def brew_in_errata
    return '✔  ' + brew if in_errata?
    return '✘  ' + brew if brew && (!can_be_shipped? || !in_shipped_list?)
    return  brew # else
  end

  # Probe the mead scheduler and ask if this package can be shipped or not
  #
  # Returns: boolean
  def in_shipped_list?
    ans = ''
    Net::HTTP.start('mead.usersys.redhat.com') do |http|
      resp = http.get("/mead-scheduler/rest/package/eap6/#{name}/shipped")
      ans = resp.body
    end
    ans == 'YES'
  end

  # Determines whether this package is already included inside an errata or not.
  #
  # Returns: boolean
  def in_errata?
    !in_errata.blank? && !brew.blank? && (in_errata.strip == brew.strip)
  end

  # Return a string representation of the rpmdiff status associated with it.
  #
  # If the rpmdiff_status column is empty, return an empty string instead
  #
  # Returns: string
  def rpmdiff_info
    if rpmdiff_status.blank?
      ''
    else
      RPMDIFF_INFO[rpmdiff_status.to_i][:status]
    end
  end

  # Return the errata rpmdiff link associated with this package.
  #
  # If the rpmdiff_id column is empty, return an empty string instead
  #
  # Returns: string
  def rpmdiff_link
    if rpmdiff_id.blank?
      ''
    else
      'https://errata.devel.redhat.com/rpmdiff/show/' + rpmdiff_id
    end
  end

  # Return a css color style depending on the current rpmdiff status
  #
  # Returns: string
  def rpmdiff_style
    if rpmdiff_status.blank?
      ''
    else
      RPMDIFF_INFO[rpmdiff_status.to_i][:style]
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
    if brew.nil? || brew.empty? || latest_brew_nvr.nil? || latest_brew_nvr.empty?
      ''
    elsif brew == latest_brew_nvr
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
    [mead, brew].each do |item|
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

  protected

  def all_from_packages_of(from_relationships, relationship_name)
    packages = []
    from_relationships.each do |from_relationship|
      if from_relationship.relationship.name == relationship_name
        packages << from_relationship.from_package
        packages << all_from_packages_of(from_relationship.from_package.from_relationships, relationship_name)
      end
    end
    packages.flatten.uniq
  end

  def all_to_packages_of(to_relationships, relationship_name)
    packages = []
    to_relationships.each do |to_relationship|
      if to_relationship.relationship.name == relationship_name
        packages << to_relationship.to_package
        packages << all_to_packages_of(to_relationship.to_package.to_relationships, relationship_name)
      end
    end
    packages.flatten.uniq
  end

  def self.distinct_in_tasks(tasks)
    Package.all(:select => 'distinct name',
                :conditions => ['task_id in (?)', Task.tasks_to_ids(tasks)],
                :order => 'name')
  end

  def self.distinct_in_tasks_can_show(tasks)
    task_ids = Task.tasks_to_ids(tasks)
    can_show_status_ids = []
    task_ids.each do |task_id|
      Status.find_all_can_show_by_task_id_in_global_scope(task_id).each do |status|
        can_show_status_ids << status.id
      end
    end

    Package.all(:select => 'distinct name',
                :conditions => ['task_id in (?) and (status_id in (?) or status_id is NULL)', task_ids, can_show_status_ids.uniq],
                :order => 'name')
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
