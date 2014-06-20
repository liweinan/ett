class AddMeadLinkToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :mead_link, :string
  end

  def self.down
    remove_column :packages, :mead_link
  end
end
