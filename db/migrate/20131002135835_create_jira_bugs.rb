class CreateJiraBugs < ActiveRecord::Migration
  def self.up
    create_table :jira_bugs do |t|
    	t.string	:id
    	t.integer	:package_id
    	t.integer	:creator_id
    	t.string	:summary
    	t.string	:reporter
    	t.timestamps
    end
  end

  def self.down
    drop_table :jira_bugs
  end
end
