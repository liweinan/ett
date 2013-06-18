class Setting < ActiveRecord::Base
  #default_value_for :is_global, 'No' #Deprecated, we now use product_id to judge
  default_value_for :props, 0
  default_value_for :actions, 0
  default_value_for :enabled, 'No'
  default_value_for :show_xattrs, 'No'
  default_value_for :enable_xattrs, 'No'

  PROPS = {:creator => 0b1, :commenter => 0b10, :assignee => 0b100}
  ACTIONS = {:created => 0b1, :updated => 0b10, :commented => 0b100}

  belongs_to :product

  def self.system_settings
    Setting.find(:first, :conditions => "product_id IS NULL")
  end

  def is_system_setting?
    self.product.blank?
  end

  def self.activated?(product, action)
    setting = enabled_in_product?(product) ? setting_of_product(product) : Setting.system_settings
    setting.actions & action > 0
  end

  def self.all_recipients_of_package(package, editor, action)
    setting = enabled_in_product?(package.product) ? setting_of_product(package.product) : Setting.system_settings
    recipients = setting.recipients
    props = setting.props

    if action == :create
      # package creation is most simple
      # Firstly it doesn't contain comments
      # Secondly no need to send notification to creator
      # send notifications to commenters and assignee
      if (props & Setting::PROPS[:assignee] > 0) && !package.assignee.blank?
        unless same_person?(package.assignee, package.creator)
          recipients += ", #{package.assignee.email}"
        end
      end
    end

    if action == :edit
      # send notifications to creators and assignee and commenters
      if (props & Setting::PROPS[:creator] > 0)
        unless same_person?(package.creator, editor)
          recipients += ", #{package.creator.email}"
        end
      end

      if (props & Setting::PROPS[:assignee] > 0) && !package.assignee.blank?
        unless same_person?(package.assignee, editor)
          recipients += ", #{package.assignee.email}"
        end
      end

      if props & Setting::PROPS[:commenter] > 0
        debugger
        package.commenters.each do |commenter|
          unless same_person?(commenter, editor)
            recipients += ", #{commenter.email}"
          end
        end
      end
    end

    if action == :comment
      # send notifications to creators and assignee and other commenters
      if (props & Setting::PROPS[:creator] > 0)
        unless same_person?(package.creator, editor)
          recipients += ", #{package.creator.email}"
        end
      end

      if (props & Setting::PROPS[:assignee] > 0) && !package.assignee.blank?
        unless same_person?(package.assignee, editor)
          recipients += ", #{package.assignee.email}"
        end
      end

      if props & Setting::PROPS[:commenter] > 0
        debugger
        package.commenters.each do |commenter|
          unless same_person?(commenter, editor)
            recipients += ", #{commenter.email}"
          end
        end
      end
    end

    recipients
  end

  def user_conatined_in?(commenter, recipients)
    if commenter.class == User.class
      commenter = commenter.email
    end

    if commenter.blank? || recipients.blank?
      return false
    end

    recipients.include?(commenter.to_s)
  end

  def self.same_person?(person1, person2)
    cleanup(person1) == cleanup(person2)
  end

  def self.cleanup(person)
    return nil if person.blank?

    if person.class == User
      person = person.id
    else
      person = person.to_i
    end
    person
  end

  def show_xattrs?
    self.show_xattrs == 'Yes' && self.enabled?
  end

  def enable_xattrs?
    self.enable_xattrs == 'Yes' && self.enabled?
  end

  def enabled?
    self.enabled == 'Yes'
  end

  def self.enabled_in_product?(product)
    setting = setting_of_product(product.id)
    !setting.blank? && setting.enabled == 'Yes'
  end

  def self.setting_of_product(product)
    if product.class == Product
      Setting.find_by_product_id(product.id)
    else
      Setting.find_by_product_id(product.to_i)
    end
  end
end
