class ComponentView < ActiveRecord::Base
  belongs_to :component
  belongs_to :task
end
