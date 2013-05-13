class AddCloseLabelToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :close_label_id, :integer
  end

  def self.down
    remove_column :settings, :close_label_id
  end
end
