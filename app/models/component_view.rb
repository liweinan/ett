class ComponentView < ActiveRecord::Base
  belongs_to :component
  belongs_to :brew_tag
end
