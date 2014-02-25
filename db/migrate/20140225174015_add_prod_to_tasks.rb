class AddProdToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :prod, :string
  end

  def self.down
    remove_column :tasks, :prod
  end
end
