src_tag_name = "jb-eap-6-rhel-6"
dst_tag_name = "jb-eap-6-rhel-6-wolf"

# Create a 'Clone' relationship to link the original and cloned tag
relationship = Relationship.new
relationship.name = "clone"
relationship.to_name = "Cloned to"
relationship.from_name = "Cloned from"
relationship.save

# Create cloned tag
dst_tag = BrewTag.new
dst_tag.name = dst_tag_name
dst_tag.save

# Create the new initial status to use in cloned tag
status = Status.new
status.name = "Open"
status.can_select = "Yes"
status.can_show = "Yes"
status.global = "N"
status.brew_tag = dst_tag
status.save

# Now we begin to clone all the packages to new tag
src_tag = BrewTag.find_by_name(src_tag_name)
src_tag.packages.each do |src_package|
 dst_package = src_package.clone #
 dst_package.brew_tag = dst_tag
 dst_package.status = status # Initialize status to 'Open'
 dst_package.marks = [] # clear all marks
 dst_package.assignee = nil
 dst_package.p_attachments = []
 dst_package.save!

 pr = PackageRelationship.new
 pr.from_package = src_package
 pr.to_package = dst_package
 pr.relationship = relationship
 pr.save!
end

####Don't forget to add an option: whether or not to clone 'deleted' packages!
####And: clone global statuses as-is.
