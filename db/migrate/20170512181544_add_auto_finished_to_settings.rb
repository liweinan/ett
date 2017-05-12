class AddAutoFinishedToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :auto_finished, :string
  end

  def self.down
    remove_column :settings, :auto_finished
  end
end
