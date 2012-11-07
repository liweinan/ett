class RenameReceipts < ActiveRecord::Migration
  def self.up
    rename_column :settings, :receipts, :recipients
  end

  def self.down
    rename_column :settings, :recipients, :receipts
  end
end
