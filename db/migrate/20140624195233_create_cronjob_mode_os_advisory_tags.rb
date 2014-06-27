class CreateCronjobModeOsAdvisoryTags < ActiveRecord::Migration
  def self.up
    create_table :cronjob_mode_os_advisory_tags do |t|
      t.integer :cronjob_mode_id
      t.integer :os_advisory_tag_id

      t.timestamps
    end
  end

  def self.down
    drop_table :cronjob_mode_os_advisory_tags
  end
end
