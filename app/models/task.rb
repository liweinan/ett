class Task < ActiveRecord::Base
#  acts_as_tree
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

  has_one :setting, :class_name => 'Setting', :foreign_key => 'task_id'

  belongs_to :workflow

  acts_as_textiled :description

  LINK = {:tag => 0, :package => 1}

  def self.tasks_to_ids(tasks)
    task_ids = []
    tasks.each do |task|
      task_ids << task.id
    end
    task_ids
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

  def readonly?
    !ReadonlyTask.find_by_task_id(id).blank?
  end

  def self.readonly?(task)
    !ReadonlyTask.find_by_task_id(task.id).blank?
  end

end
