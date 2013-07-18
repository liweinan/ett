class AddUseBzIntegrationToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :use_bz_integration, :string
  end

  def self.down
    remove_column :settings, :use_bz_integration
  end
end
