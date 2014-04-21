class AddTargetTagAndBuildTagToOsAdvisoryTag < ActiveRecord::Migration
  def self.up
    add_column :os_advisory_tags, :target_tag, :string
    add_column :os_advisory_tags, :build_tag, :string
  end

  def self.down
    remove_column :os_advisory_tags, :build_tag
    remove_column :os_advisory_tags, :target_tag
  end
end
