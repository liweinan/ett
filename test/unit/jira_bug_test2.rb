require '../../app/models/jira_bug_clean'
require 'json'
bug = JiraBug.new('mtjandra', '0ff1c14ljboss')
x = bug.get("12410378")
puts JSON.pretty_generate(x)
