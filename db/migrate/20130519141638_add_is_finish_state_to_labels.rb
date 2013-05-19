class AddIsFinishStateToLabels < ActiveRecord::Migration
  def self.up
    add_column :labels, :is_finish_state, :string
  end

  def self.down
    remove_column :labels, :is_finish_state
  end
end
