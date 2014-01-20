class AddBugzillaEmailToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :bugzilla_email, :string
  end

  def self.down
    remove_column :users, :bugzilla_email
  end
end
