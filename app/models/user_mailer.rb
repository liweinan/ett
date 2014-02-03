class UserMailer < ActionMailer::Base

  def reset_password(recipient)
    subject 'Reset Password (ETT)'
    recipients recipient.email
    from 'ett_usersys@redhat.com'
    sent_on Time.now
    body :body => "http://ett.usersys.redhat.com/users/#{recipient.id}/edit?reset_code=#{recipient.reset_code}"
  end

end
