open 'EAP_51_errata_pkg_names_sort.txt' do |file|
  open 'packages.yml', 'w' do |o|
    o.puts('---')    
    file.each do |l|
      o.puts '- !ruby/object:Package'
      o.puts '  attributes:'
      o.puts '    name: ' + l
      o.puts '    created_at: ' + Time.now.to_s
      o.puts '    dist: jb-eap-5-rhel-6'
      o.puts '    state: Open'
      o.puts '  attributes_cache: {}'
      o.puts ''
    end
  end
end