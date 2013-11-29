class CreateOsAdvisoryTag < ActiveRecord::Migration
  def self.up
    create_table :os_advisory_tags do |t|
      t.string :os_arch
      t.string :advisory
      t.string :candidate_tag
      t.integer :task_id

      t.timestamps
    end
  end

  def self.down
    drop_table :os_advisory_tags
  end
end
