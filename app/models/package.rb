class Package < ActiveRecord::Base
  versioned # versioned plugin sucks, try to withdrawal the usage of it.
            #  STATUS = [ 'Open', 'Assigned', 'Finished', 'Uploaded', 'Deleted' ]
            #  STATUS_FOR_CHOICE = [ 'Assigned', 'Finished', 'Uploaded', 'Deleted' ]
            #  SORTED_STATUS = ['Open', 'Assigned', 'Finished', 'Uploaded', 'Deleted']
  PROPS = {:manage => 0b1}

  DISTS = ['jb-eap-5-rhel-6', 'jb-eap-5-jdk5-rhel-6', 'jb-eap-4.3-rhel-6']

  SKIP_FIELDS = ['id', 'updated_at', 'updated_by', 'created_by', 'created_at']
  MEAD_ACTIONS = {:open => 'open', :needsync => 'needsync', :done => 'done'}

  RPMDIFF_INFO = {
    0 => {:status => "PASSED", :style => "background-color: #b5f36d;"},
    1 => {:status => "INFO", :style => "background-color: #b5f36d;"},
    2 => {:status => "WAIVED", :style => "background-color: #b5f36d;"},
    3 => {:status => "NEEDS INSPECTION", :style => "background-color: #ff5757;"},
    4 => {:status => "FAILED", :style => "background-color: #ff5757;"},
    498 => {:status => "TEST IN PROGRESS", :style => "background-color: #b2f4ff;"},
    499 => {:status => "UNPACKING FILES", :style => "background-color: #b2f4ff;"},
    500 => {:status => "QUEUED FOR TEST", :style => "background-color: #b2f4ff;"},
    -1 => {:status => "DUPLICATE", :style => "background-color: #b2ffa1;"}
  }
  acts_as_textiled :notes
  acts_as_commentable

  belongs_to :user #assignee
  belongs_to :assignee, :class_name => "User", :foreign_key => "user_id"
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :task
  belongs_to :status

  has_many :assignments, :dependent => :destroy
  has_many :tags, :through => :assignments
  has_many :bz_bugs, :class_name => "BzBug", :foreign_key => "package_id", :order => "created_at"

  #has_and_belongs_to_many :components

  has_many :to_relationships, :class_name => "PackageRelationship", :foreign_key => "from_package_id", :dependent => :destroy
  has_many :from_relationships, :class_name => "PackageRelationship", :foreign_key => "to_package_id", :dependent => :destroy

  has_many :p_attachments, :dependent => :destroy

  has_many :changelogs, :class_name => "Changelog", :foreign_key => "package_id", :dependent => :destroy

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

  def self.per_page
    10
  end

  def can_edit_version?
    if status.respond_to?(:code)
        status.code != Status::CODES[:finished]
    else
      true
    end
  end

  def commenters
    user_ids = Comment.find_by_sql("select distinct user_id from comments where commentable_type='Package' and commentable_id=#{id}")
    commenters = []
    user_ids.each do |user_id|
      commenters << User.find(user_id.user_id)
    end
    commenters
  end

  def each_attr
    self.attributes.each do |attr|
      yield attr
    end
  end

  def deleted?
    if self.status
      self.status.name == Status.deleted_status.name
    else
      false
    end
  end

  def in_progress?
    return !time_point.blank? && time_point > 0
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
        unless PackageRelationship.all(:conditions => ["(from_package_id = ? or to_package_id = ?) and relationship_id = ?", self.id, self.id, relationship.id]).blank?
          return true
        end
      end
      false
    end
  end

  def can_be_shipped?
    self.tags.each do |tag|
      if tag.key == "Not Shipped"
        return false
      end
    end

    return true
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
    bz_bugs.map {|bz| bz = bz.bz_id }.join(" ")
  end

  def to_s
    str = "Name: " + name + "\n"
    str += "Created By: " + creator.name + "(#{creator.email})" + "\n"
    str += "Created At: " + created_at.to_s + "\n"
    str += "Belongs To: " + task.name + "\n"
    unless assignee.blank?
      str += "Assignee: " + assignee.name + "(#{assignee.email})" + "\n"
    end
    str
  end

  def pending_bz_bugs
    BzBug.all(:conditions => ['package_id = ? and bz_action is not null', self.id])
  end

  def errata_related_bz
    errata_bz = []
    bz_bugs.each do |bug|

      if (bug.bz_status == "MODIFIED") &&
         (bug.summary.start_with? "Upgrade") &&
         (bug.component.include? "RPMs") &&
         (bug.keywords.include? "Rebase")
        errata_bz.push bug.bz_id
      end
    end
    errata_bz.join(",")
  end

  def bz_bug_ids
    # want to return a list of all the ids in the :bz_bugs field
    return bz_bugs.map { |bug| bug["bz_id"] }
  end

  def nvr_and_nvr_in_errata?
    if in_errata and brew and (in_errata == brew):
      brew + " ✔  In Errata!"
    else
      brew
    end
  end

  def in_shipped_list?
    open('/var/www/html/shipped-list') { |f| f.grep("#{name}\n")  }
  end

  def brew_and_is_in_errata?
    if in_errata and brew and (in_errata == brew)
        "✔  " + brew
    elsif brew and (!can_be_shipped? or !in_shipped_list?)
        "✘  " + brew
    else
      brew
    end
  end

  def rpmdiff_info
    if rpmdiff_status
      RPMDIFF_INFO[rpmdiff_status.to_i][:status]
    else
      ''
    end
  end

  def rpmdiff_link
    if rpmdiff_id
      'https://errata.devel.redhat.com/rpmdiff/show/' + rpmdiff_id
    else
      ''
    end
  end

  def rpmdiff_style
    if rpmdiff_status
      RPMDIFF_INFO[rpmdiff_status.to_i][:style]
    else
      ''
    end
  end

  def version_style

    if ver.nil? || ver.empty?
      return ''
    end

    first_part_ver = ver.gsub(/\.([^.]*)$/, '').gsub('-', '_')
    second_part_ver = ver.gsub(first_part_ver + '.', '').gsub('-', '_')

    [mead, brew].each do |item|
      if !item.nil? && !item.empty?
        if !item.include?(first_part_ver) || !item.include?(second_part_ver)
          return "background-color: #ff5757;"
        end
      end
    end

    # if they are valid, return empty
    return ''
  end

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
    Package.all(:select => "distinct name", :conditions => ["task_id in (?)", Task.tasks_to_ids(tasks)], :order => "name")
  end

  def self.distinct_in_tasks_can_show(tasks)
    task_ids = Task.tasks_to_ids(tasks)
    can_show_status_ids = []
    task_ids.each do |task_id|
      Status.find_all_can_show_by_task_id_in_global_scope(task_id).each do |status|
        can_show_status_ids << status.id
      end
    end

    Package.all(:select => "distinct name", :conditions => ["task_id in (?) and (status_id in (?) or status_id is NULL)", task_ids, can_show_status_ids.uniq], :order => "name")
  end

  def validate
    p = Package.find_by_name_and_task_id(self.name.strip, self.task_id)
    if p && p.id != self.id
      errors.add(:name, " - Package name cannot be duplicate under one task!")
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
