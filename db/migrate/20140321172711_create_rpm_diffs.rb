class CreateRpmDiffs < ActiveRecord::Migration
  def self.up
    create_table :rpm_diffs do |t|
      t.string :in_errata
      t.string :rpmdiff_status
      t.string :rpmdiff_id

      t.timestamps
    end
  end

  def self.down
    drop_table :rpm_diffs
  end
end
