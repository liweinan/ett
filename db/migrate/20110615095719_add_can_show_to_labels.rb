class AddCanShowToLabels < ActiveRecord::Migration
  def self.up
    add_column :labels, :can_show, :string
  end

  def self.down
    remove_column :labels, :can_show
  end
end
