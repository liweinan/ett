class AddEnableXattrsToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :enable_xattrs, :string
  end

  def self.down
    remove_column :settings, :enable_xattrs
  end
end
