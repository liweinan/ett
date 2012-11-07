class AddDefaultTagToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :default_tag, :string
  end

  def self.down
    remove_column :settings, :default_tag
  end
end
