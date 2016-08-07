# == Schema Information
#
# Table name: jira_bugs
#
#  id             :integer          not null, primary key
#  package_id     :integer
#  creator_id     :integer
#  summary        :string(255)
#  status         :string(255)
#  assignee       :string(255)
#  last_synced_at :datetime
#  jira_bug       :string(255)
#

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

