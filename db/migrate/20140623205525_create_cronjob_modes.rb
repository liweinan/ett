class CreateCronjobModes < ActiveRecord::Migration
  def self.up
    create_table :cronjob_modes do |t|
      t.string :mode
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :cronjob_modes
  end
end
