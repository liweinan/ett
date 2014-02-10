class Notify
  class Comment
    def self.create(commenter, link, package, comment, recipients)
      body = Hash.new
      subject = "#{commenter.name} added comment to #{package.name}"
      body[:link] = link
      body[:sender] = commenter.name
      body[:action] = "added comment to #{package.name}"
      body[:detail] = comment.comment(:plain)
      body[:updated_at] = comment.created_at
      Notify.notify(recipients, subject, body)
    end
  end

  class Package
    def self.create(creator, link, package, recipients)
      body = Hash.new
      subject = "#{creator.name} created package: #{package.name}"
      body[:link] = link
      body[:sender] = creator.name
      body[:action] = "created package: #{package.name}"
      body[:detail] = package.to_s
      body[:updated_at] = package.created_at

      Notify.notify(recipients, subject, body)
    end

    def self.strip_html(str)
      str ||= ''
      str.gsub(/<\/?[^>]*>/, '')
    end

    def self.update(editor, link, package, recipients, latest_changes_package=nil)
      body = Hash.new
      subject = "#{editor.name} edited package: #{package.name}"
      body[:link] = link
      body[:sender] = editor.name
      body[:action] = "edited package #{package.name}"

      detail = ''
      if latest_changes_package.nil?
        hashes = package.latest_changes
      else
        hashes = latest_changes_package
      end
      hashes.keys.each do |key|
        if key == 'notes'
          detail += "\n#{key.capitalize}\n--------------------\n***Was***\n #{strip_html(hashes[key][0])}\n\n***Now***\n #{strip_html(hashes[key][1])}\n\n"
        elsif key == 'user_id'
          prev = nil
          now = nil
          prev = User.find(hashes[key][0]).name unless hashes[key][0].blank?
          now = User.find(hashes[key][1]).name unless hashes[key][1].blank?
          detail += "\nAssignee\n--------------------\n***Was***\n #{prev}\n\n***Now***\n #{now}\n\n"
        elsif key == 'status_id'
          prev = nil
          now = nil
          prev = Status.find(hashes[key][0]).name unless hashes[key][0].blank?
          now = Status.find(hashes[key][1]).name unless hashes[key][1].blank?
          detail += "\nStatus\n--------------------\n***Was***\n #{prev}\n\n***Now***\n #{now}\n\n"
        elsif key != 'status_changed_at'
          prev = hashes[key][0]
          now = hashes[key][1]
          detail += "\n#{key} changed\n--------------------\n***Was***\n #{prev}\n\n***Now***\n #{now}\n\n"
        end
      end

      body[:detail] = detail
      body[:updated_at] = package.created_at
      Notify.notify(recipients, subject, body)
    end
  end

  def self.notify(recipients, subject, body)

    if recipients.class == String
      recipients = text_to_array(recipients)
    end

    recipients.each do |recipient|
      unless recipient.blank?
        email = NotificationMailer.create_notify(recipient, subject, body)
        Thread.new do
          NotificationMailer.deliver(email)
        end
      end
    end
  end

  def self.text_to_array(recipients_text)
    if recipients_text.class == String
      return recipients_text.split(',').delete_if { |token| token.blank? }.uniq
    elsif recipients_text.class == Array
      return recipients_text.delete_if { |token| token.blank? }.uniq
    end
    []
  end

  #def text_to_array(recipients_text)
  #  unless recipients_text.blank?
  #    recipients = recipients_text.split(/\s+|,/)
  #    return uniq_array(recipients)
  #  end
  #  []
  #end
  #
  #def uniq_array(array)
  #  array.inject([]) { |result, h| result << h unless result.include?(h); result }
  #end
end
