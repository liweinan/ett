class RenameDoctypeToKeywordsInTableBzBugs < ActiveRecord::Migration
  def self.up
    rename_column :bz_bugs, :doc_type, :keywords
  end

  def self.down
    rename_column :bz_bugs, :keywords, :doc_type
  end
end
