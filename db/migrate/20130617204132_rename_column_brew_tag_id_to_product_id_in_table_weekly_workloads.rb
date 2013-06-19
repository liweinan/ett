class RenameColumnBrewTagIdToProductIdInTableWeeklyWorkloads < ActiveRecord::Migration
  def self.up
      rename_column :weekly_workloads, :brew_tag_id, :product_id
  end

  def self.down
      rename_column :weekly_workloads, :product_id, :brew_tag_id
  end
end
