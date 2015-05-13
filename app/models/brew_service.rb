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
      get_brew_item('getBuild', nvr, 'task_id', taskinfo_link)
	  end

    def get_brew_maven_link(nvr)
      result = get_brew_item('getMavenBuild', nvr, 'build_id', buildinfo_link)
      if result.nil?
        get_brew_rpm_link(nvr)
      else
        result
      end
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
        buildinfo_link + call[key].to_s
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