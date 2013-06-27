class RenameLabelStatsToStatusStats < ActiveRecord::Migration
  def self.up
      rename_table :label_stats, :status_stats
  end

  def self.down
      rename_table :status_stats, :label_stats
  end
end
