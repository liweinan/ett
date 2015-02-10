class RemoveBrewLinkFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :brew_link
  end

  def self.down
    add_column :users, :brew_link, :string
  end
end
