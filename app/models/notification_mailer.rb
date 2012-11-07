class NotificationMailer < ActionMailer::Base
  def notify(recipient, subject, content)
    subject "#{subject} (ETT)"
    recipients recipient
    from 'ett_usersys@redhat.com'
    sent_on Time.now
    body :body => content
  end

end
