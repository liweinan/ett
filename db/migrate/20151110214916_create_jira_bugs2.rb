class CreateJiraBugs2 < ActiveRecord::Migration
  def self.up
    create_table :jira_bugs do |t|
      t.integer :package_id
      t.integer :creator_id
      t.string :summary
      t.string :status
      t.string :assignee
      t.timestamp :last_synced_at
      t.string :jira_bug
    end
  end

  def self.down
  end
end
