require 'net/http'

################################################################################
# Service class used for anything concerning brew
################################################################################
class BrewService

	############################################################################
	# Define class methods here
	############################################################################
	class << self
	  def get_brew_rpm_link(nvr, retries = 3)
      get_brew_item('getBuild', nvr, 'build_id', buildinfo_link)
	  end

    def get_brew_maven_link(nvr)
      get_brew_rpm_link(nvr)
    end

    def get_scm_url_brew(mead_nvr)
      server = XMLRPC::Client.new('brewhub.devel.redhat.com', '/brewhub', 80)

      return nil if mead_nvr.nil?

      begin
        param = server.call('getBuild', mead_nvr)
        unless param.nil?
          param['task_id'].nil? ? nil : server.call('getTaskRequest', param['task_id'])[0]
        else
          nil
        end
      rescue XMLRPC::FaultException
        nil
      end
    end

    # should it be put there? should the brew_service know about the models?
    def update_previous_version_of_packages(task)
      begin
        server = XMLRPC::Client.new("brewhub.devel.redhat.com", "/brewhub", 80)
        task.packages.each do |package|
          next if !package.can_be_shipped?

          # use package.get_pkg_name for SCL packages
          param = server.call("getLatestRPMS", task.previous_version_tag, package.get_pkg_name)
          nvr_info = param[1][0]
          unless nvr_info.nil?
            version = nvr_info['version']
            release = nvr_info['release']
            release = release.split('.')[1].gsub('_', '-')
            if release.include?("redhat")
              abbreviated_version = version + '.' + release
            else
              abbreviated_version = version
            end
            package.previous_version = abbreviated_version
            package.save
          end
        end
      rescue Exception => e
        puts "Error for task #{task.name} in finding previous version of packages"
        puts "Probably because its previous version tag is empty"
        puts "Previous_version_tag of task is: #{task.previous_version_tag}"
      end
    end




	  private
	  def get_xmlrpc_client
	  	XMLRPC::Client.new("brewhub.devel.redhat.com", "/brewhub", 80)
	  end

    def taskinfo_link
      'https://brewweb.devel.redhat.com/taskinfo?taskID='
    end

    def buildinfo_link
      'https://brewweb.devel.redhat.com/buildinfo?buildID='
    end

    def get_brew_item(method, nvr, key, info_link, retries = 3)
      server = get_xmlrpc_client
      begin
        call = server.call(method, nvr)
        info_link + call[key].to_s
      rescue Exception => e
        if retries.zero?
          nil
        else
          puts "Calling #{method} for brew: attempt remaining: #{retries}"
          get_brew_item(method, nvr, key, info_link, retries - 1)
        end
      end
    end
	end
end
