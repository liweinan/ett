class JiraBug < ActiveRecord::Base
# assignee_name
# summary
# status
# jira_name
  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
  belongs_to :package, :class_name => 'Package', :foreign_key => 'package_id'

  def creator
  	return User.find(self.creator_id)
  end
end

