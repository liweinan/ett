class Task < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  default_value_for :can_show, 'Yes'
  default_value_for :total_manual_track_time, 0

  has_many :tags, :dependent => :destroy
  has_many :packages, :dependent => :destroy
  has_many :statuses, :dependent => :destroy

  has_many :os_advisory_tags, :dependent => :destroy

  has_many :component_views
  has_many :components, :through => :component_views

  has_many :task_group_to_tasks
  has_many :task_groups, :through => :task_group_to_tasks


  has_one :setting, :class_name => 'Setting', :foreign_key => 'task_id'

  belongs_to :workflow

  if Rails::VERSION::STRING < "4"
    acts_as_textiled :description
  end

  LINK = {:tag => 0, :package => 1}

  def self.tasks_to_ids(tasks)
    task_ids = []
    tasks.each do |task|
      task_ids << task.id
    end
    task_ids
  end

  def self.from_task_ids(task_ids)
    tasks = []
    task_ids.each do |task_id|
      task = Task.find(task_id.to_i)
      tasks << task
    end
    tasks
  end

  def unclosed_pr_pkgs
    self.packages.select do |package|
      !package.github_pr.blank? &&
      (package.github_pr_closed.nil? || package.github_pr_closed == false)
    end
  end

  def self.all_that_have_package_with_name(name)
    Task.all(:conditions => ['id in (select task_id from packages where name = ?)', name])
  end

  def use_bz_integration?
    if setting.blank?
      false
    else
      setting.use_bz_integration?
    end
  end

  def use_jira_integration?
    if setting.blank?
      false
    else
      setting.use_jira_integration?
    end
  end

  def use_mead_integration?
    if setting.blank?
      false
    else
      setting.use_mead_integration?
    end
  end

  def read_only_task?
    self.read_only_task
  end

  def active_packages # find the packages of the task which the workload time need to be tracked.
    # If the package status's 'is_track_time' field is not 'No', then the workload of this package needs to be tracked.
    # So we will consider this package as active.
    # For example if the package is in 'Deleted' status, and because 'Deleted' status's 'is_track_time' is set to 'No',
    # so we think the packages marked in 'Delete' status is inactive.
    Package.all(:conditions => ["task_id = ? and status_id in (select id from statuses where is_track_time != 'No') or status_id is null", id])
  end

  def active?
    self.active == "1"
  end

  def sorted_os_advisory_tags
    OsAdvisoryTag.all(:conditions => ['task_id = ?', self.id], :order => :priority)
  end

  def distros
    tags = self.sorted_os_advisory_tags
    distros = []
    tags.each do |tag|
      distros << tag.os_arch
    end
    distros
  end

  def primary_os_advisory_tag
    primary = sorted_os_advisory_tags[0]
    if primary.blank?
      OsAdvisoryTag.new
    else
      primary
    end
  end

  def has_pkg_with_optional_errata?
    Package.find(:all,
                 :conditions => ['task_id = ? and errata > ?', self.id, '']).count != 0
  end
end
