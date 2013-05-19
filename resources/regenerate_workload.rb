start = Date.parse("2013-2-1")
to = Date.today.at_end_of_week

while start < to
  from = start.at_beginning_of_week.to_s
  #system "curl http://ett.usersys.redhat.com/workload/generate_weekly_workload?from=#{from}"

  require 'net/http'
  Net::HTTP.get(URI.parse("http://127.0.0.1:3000/workload/generate_weekly_workload?from=#{from}"))

  start = start.at_end_of_week + 1.day
end