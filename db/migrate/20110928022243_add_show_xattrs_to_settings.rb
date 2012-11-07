class AddShowXattrsToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :show_xattrs, :string
  end

  def self.down
    remove_column :settings, :show_xattrs
  end
end
