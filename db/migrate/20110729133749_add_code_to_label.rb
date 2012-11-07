class AddCodeToLabel < ActiveRecord::Migration
  def self.up
    add_column :labels, :code, :string
  end

  def self.down
    remove_column :labels, :code
  end
end
