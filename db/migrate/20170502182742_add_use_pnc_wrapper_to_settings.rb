class AddUsePncWrapperToSettings < ActiveRecord::Migration
  def self.up
    add_column :settings, :use_pnc_wrapper, :string
  end

  def self.down
    remove_column :settings, :use_pnc_wrapper
  end
end
