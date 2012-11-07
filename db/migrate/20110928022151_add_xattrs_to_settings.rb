class AddXattrsToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :xattrs, :text
  end

  def self.down
    remove_column :settings, :xattrs
  end
end
