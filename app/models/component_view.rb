# == Schema Information
#
# Table name: component_views
#
#  id           :integer          not null, primary key
#  component_id :integer
#  task_id      :integer
#

class ComponentView < ActiveRecord::Base
  belongs_to :component
  belongs_to :task
end
