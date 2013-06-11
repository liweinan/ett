class AddSummaryToBzBugs < ActiveRecord::Migration
  def self.up
    add_column :bz_bugs, :summary, :string
  end

  def self.down
    remove_column :bz_bugs, :summary
  end
end
