class AddUseMeadIntegrationToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :use_mead_integration, :string
  end

  def self.down
    remove_column :settings, :use_mead_integration
  end
end
