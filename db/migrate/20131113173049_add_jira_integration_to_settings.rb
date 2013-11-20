class AddJiraIntegrationToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :use_jira_integration, :string
  end

  def self.down
    remove_column :settings, :use_jira_integration
  end
end
