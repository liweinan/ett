class AddPriorityToOsAdvTags < ActiveRecord::Migration
  def self.up
    add_column :os_advisory_tags, :priority, :string
  end

  def self.down
    remove_column :os_advisory_tags, :priority
  end
end
