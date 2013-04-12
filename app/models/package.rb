class Package < ActiveRecord::Base
  versioned # versioned plugin sucks, try to withdrawl the usage of it.
            #  STATUS = [ 'Open', 'Assigned', 'Finished', 'Uploaded', 'Deleted' ]
            #  STATUS_FOR_CHOICE = [ 'Assigned', 'Finished', 'Uploaded', 'Deleted' ]
            #  SORTED_STATUS = ['Open', 'Assigned', 'Finished', 'Uploaded', 'Deleted']
  PROPS = {:manage => 0b1}

  DISTS = ['jb-eap-5-rhel-6', 'jb-eap-5-jdk5-rhel-6', 'jb-eap-4.3-rhel-6']

  SKIP_FIELDS = ['id', 'updated_at', 'updated_by', 'created_by', 'created_at']

  acts_as_textiled :notes
  acts_as_commentable

  belongs_to :user #assignee
  belongs_to :assignee, :class_name => "User", :foreign_key => "user_id"
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :brew_tag
  belongs_to :label

  has_many :assignments, :dependent => :destroy
  has_many :marks, :through => :assignments

  #has_and_belongs_to_many :components

  has_many :to_relationships, :class_name => "PackageRelationship", :foreign_key => "from_package_id", :dependent => :destroy
  has_many :from_relationships, :class_name => "PackageRelationship", :foreign_key => "to_package_id", :dependent => :destroy

  has_many :p_attachments, :dependent => :destroy

  has_many :changelogs, :class_name => "Changelog", :foreign_key => "package_id", :dependent => :destroy

  validates_presence_of :name
  validates_presence_of :brew_tag_id
  validates_presence_of :created_by
  validates_presence_of :updated_by

  default_value_for :time_consumed, 0
  default_value_for :time_point, 0
  default_value_for :label_changed_at, Time.now

  def self.per_page
    10
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
    if self.label
      self.label.name == Label.deleted_label.name
    else
      false
    end
  end

  def in_progress?
    return !time_point.blank? && time_point > 0
  end

  def set_deleted
    self.label = Label.deleted_label
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

  def all_relationships_of(relationship_name = nil)
    relationship = Relationship.find_by_name(relationship_name)
    unless relationship.blank?
      packages = []
      packages << all_from_packages_of(self.from_relationships, relationship_name)
      packages << all_to_packages_of(self.to_relationships, relationship_name)
      packages.flatten
    end
  end

  def to_s
    str = "Name: " + name + "\n"
    str += "Created By: " + creator.name + "(#{creator.email})" + "\n"
    str += "Created At: " + created_at.to_s + "\n"
    str += "Belongs To: " + brew_tag.name + "\n"
    unless assignee.blank?
      str += "Assignee: " + assignee.name + "(#{assignee.email})" + "\n"
    end
    str
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

  def self.distinct_in_tags(brew_tags)
    Package.all(:select => "distinct name", :conditions => ["brew_tag_id in (?)", BrewTag.brew_tags_to_ids(brew_tags)], :order => "name")
  end

  def self.distinct_in_tags_can_show(brew_tags)
    brew_tag_ids = BrewTag.brew_tags_to_ids(brew_tags)
    can_show_label_ids = []
    brew_tag_ids.each do |tag_id|
      Label.find_all_can_show_by_brew_tag_id_in_global_scope(tag_id).each do |label|
        can_show_label_ids << label.id
      end
    end

    Package.all(:select => "distinct name", :conditions => ["brew_tag_id in (?) and (label_id in (?) or label_id is NULL)", brew_tag_ids, can_show_label_ids.uniq], :order => "name")
  end

  def validate
    p = Package.find_by_name_and_brew_tag_id(self.name.strip, self.brew_tag_id)
    if p && p.id != self.id
      errors.add(:name, " - Package name cannot be duplicate under one tag!")
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
