class AddMeadActionToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :mead_action, :string
  end

  def self.down
    remove_column :packages, :mead_action
  end
end
