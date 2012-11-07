to_be_destroyed_tag_name = "jb-eap-6-rhel-6-wolf"

to_be_destroyed_tag = BrewTag.find_by_name(to_be_destroyed_tag_name)
to_be_destroyed_tag.destroy

relationship = Relationship.find_by_name("clone")
relationship.destroy
