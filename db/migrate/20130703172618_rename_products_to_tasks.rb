class RenameProductsToTasks < ActiveRecord::Migration
  def self.up
      rename_table :products, :tasks
  end

  def self.down
      rename_table :tasks, :products
  end
end
