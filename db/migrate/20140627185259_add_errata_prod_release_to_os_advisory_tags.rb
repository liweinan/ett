class AddErrataProdReleaseToOsAdvisoryTags < ActiveRecord::Migration
  def self.up
    add_column :os_advisory_tags, :errata_prod_release, :string
  end

  def self.down
    remove_column :os_advisory_tags, :errata_prod_release
  end
end
