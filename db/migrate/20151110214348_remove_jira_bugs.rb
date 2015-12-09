class RemoveJiraBugs < ActiveRecord::Migration
  def self.up
    drop_table :jira_bugs
  end

  def self.down
  end
end
