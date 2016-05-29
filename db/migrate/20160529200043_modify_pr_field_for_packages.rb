class ModifyPrFieldForPackages < ActiveRecord::Migration
  def self.up
    change_column :packages, :github_pr, :string
  end

  def self.down
    change_column :packages, :github_pr, :integer
  end
end
