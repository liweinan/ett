class AddGlobalToLabels < ActiveRecord::Migration
  def self.up
    add_column :labels, :global, :string
  end

  def self.down
    remove_column :labels, :global
  end
end
