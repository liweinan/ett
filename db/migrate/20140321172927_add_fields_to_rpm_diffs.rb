class AddFieldsToRpmDiffs < ActiveRecord::Migration
  def self.up
    add_column :rpm_diffs, :nvr_in_errata, :string
    add_column :rpm_diffs, :package_id, :integer
    add_column :rpm_diffs, :distro, :string
  end

  def self.down
    remove_column :rpm_diffs, :nvr_in_errata
    remove_column :rpm_diffs, :package_id
    remove_column :rpm_diffs, :distro
  end
end
