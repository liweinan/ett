class CreateJiraBugs < ActiveRecord::Migration
  def self.up
    create_table :jira_bugs, {:id => false} do |t|
      t.integer :jid
    	t.string	:key
    	t.integer	:package_id
    	t.integer	:creator_id
    	t.string	:summary
    	t.string	:reporter
      t.project :project
      t.string  :issuetype
      t.integer :priority
      t.string :components
      t.string :affected_versions
      t.string :fix_versions
      t.string :security
      t.text :depends_on
    	t.timestamps
    end
  end

  def self.down
    drop_table :jira_bugs
  end
end
