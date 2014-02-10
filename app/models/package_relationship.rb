class PackageRelationship < ActiveRecord::Base
  validates_presence_of :from_package_id
  validates_presence_of :to_package_id
  validates_presence_of :relationship_id
  
  belongs_to :from_package, :class_name => 'Package', :foreign_key => 'from_package_id'
  belongs_to :to_package, :class_name => 'Package', :foreign_key => 'to_package_id'
  belongs_to :relationship, :class_name => 'Relationship', :foreign_key => 'relationship_id'

  def after_create
    if self.relationship.name == 'clone'
      Changelog.package_cloned(from_package, to_package)
    end
  end
end
