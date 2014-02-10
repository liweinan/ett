class Changelog < ActiveRecord::Base
  belongs_to :package
  belongs_to :user, :class_name => 'User', :foreign_key => 'changed_by'
  validates_presence_of :package_id
  validates_presence_of :changed_at

  default_scope :order => 'changed_at DESC'

  CATEGORY = {:comment => 'COMMENT', :update => 'UPDATE',
              :create => 'CREATE', :clone => 'CLONE', :delete => 'DELETE'}
  TEMPLATE = {
      :comment => '%s has added a comment: %s',
      :update => '%s has updated package information:',
      :create => '%s has created the package.',
      :clone => '%s has cloned the package to %s',
      :delete => '%s has deleted the package.'
  }

  def self.package_created(package)
    changelog = Changelog.new
    changelog.package_id = package.id
    changelog.changed_by = package.updated_by
    changelog.category = Changelog::CATEGORY[:create]
    changelog.changed_at = Time.now
    changelog.save
  end

  def self.comment_added(comment)
    changelog = Changelog.new
    changelog.package_id = Package.find(comment.commentable_id).id
    changelog.changed_by = comment.user_id
    changelog.category = Changelog::CATEGORY[:comment]
    changelog.references = comment.id
    changelog.changed_at = Time.now
    changelog.save
  end

  def self.package_deleted(package)
    changelog = Changelog.new
    changelog.package_id = package.id
    changelog.changed_by = package.updated_by
    changelog.category = Changelog::CATEGORY[:delete]
    changelog.changed_at = Time.now
    changelog.save
  end

  def self.package_cloned(from_package, to_package)
    changelog = Changelog.new
    changelog.package_id = from_package.id
    changelog.changed_by = from_package.updated_by
    changelog.category = Changelog::CATEGORY[:clone]
    changelog.from_value = from_package.id
    changelog.to_value = to_package.id
    changelog.changed_at = Time.now
    changelog.save
  end

  def self.package_updated(orig_package, package, orig_tags)

    Changelog.diff_fields(orig_package, package) do |attr|
      changelog = Changelog.new
      changelog.package_id = package.id
      changelog.changed_by = package.updated_by
      changelog.category = Changelog::CATEGORY[:update]
      changelog.changed_at = Time.now

      if attr == 'status_id'
        from_status = Status.find_by_id(orig_package.read_attribute(attr).to_i)
        to_status = Status.find_by_id(package.read_attribute(attr).to_i)

        if from_status.blank?
          changelog.from_value = '-'
        else
          changelog.from_value = from_status.name
        end

        if to_status.blank?
          changelog.to_value = '-'
        else
          changelog.to_value = to_status.name
        end

        changelog.references = 'status'
      elsif attr == 'user_id'
        from_assignee = orig_package.assignee
        to_assignee = package.assignee

        if from_assignee.blank?
          changelog.from_value = '-'
        else
          changelog.from_value = from_assignee.name
        end

        if to_assignee.blank?
          changelog.to_value = '-'
        else
          changelog.to_value = to_assignee.name
        end

        changelog.references = 'assignee'
      elsif attr == 'notes'
        changelog.references = 'notes'

        # TODO Thread conflict
        a_file = '/tmp/ett_tmp_' + orig_package.id.to_s + orig_package.updated_at.to_i.to_s
        File.open(a_file, 'w') do |f|
          f.puts orig_package.notes(:plain)
        end

        b_file = '/tmp/ett_tmp_' + package.id.to_s + package.updated_at.to_i.to_s
        File.open(b_file, 'w') do |f|
          f.puts package.notes(:plain)
        end

        changelog.to_value = `diff #{a_file} #{b_file}`

        File.delete a_file
        File.delete b_file
      else
        changelog.from_value = orig_package.read_attribute(attr)
        changelog.to_value = package.read_attribute(attr)
        changelog.references = attr
      end

      changelog.save
    end

    unless orig_tags == package.tags
      changelog = Changelog.new
      changelog.package_id = package.id
      changelog.changed_by = package.updated_by
      changelog.category = Changelog::CATEGORY[:update]
      changelog.changed_at = Time.now

      changelog.references = 'tags'

      changelog.from_value = ''
      orig_package.tags.each do |tag|
        changelog.from_value <<  tag.key + ' / '
      end

      changelog.to_value = ''
      package.tags.each do |tag|
        changelog.to_value << tag.key + ' / '
      end

      changelog.save

    end


  end

  protected

  def self.diff_fields(orig_ar_obj, ar_obj)

    ar_obj.attributes.keys.each do |attr|
      orig_ar_obj.write_attribute(attr, '') if orig_ar_obj.read_attribute(attr).blank?
      ar_obj.write_attribute(attr, '') if ar_obj.read_attribute(attr).blank?

      unless Package::SKIP_FIELDS.include?(attr)
        if ar_obj.read_attribute(attr).to_s.strip != orig_ar_obj.read_attribute(attr).to_s.strip
          yield attr
        end
      end
    end
  end

end
