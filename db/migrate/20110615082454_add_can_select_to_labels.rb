class AddCanSelectToLabels < ActiveRecord::Migration
  def self.up
    add_column :labels, :can_select, :string
  end

  def self.down
    remove_column :labels, :can_select
  end
end
