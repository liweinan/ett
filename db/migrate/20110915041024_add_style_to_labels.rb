class AddStyleToLabels < ActiveRecord::Migration
  def self.up
    add_column :labels, :style, :text
  end

  def self.down
    remove_column :labels, :style
  end
end
