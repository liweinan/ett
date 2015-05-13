require 'net/http'

class MeadSchedulerService

	class << self

    def get_mead_nvr_from_wrapper_nvr(brew_pkg)
      uri = URI.parse(URI.encode("#{APP_CONFIG['mead_scheduler']}/mead-brewbridge/pkg/wrapped/#{brew_pkg}"))
      res = Net::HTTP.get_response(uri)

      (res.code == '200' && !res.body.include?('ERROR')) ? res.body : nil
    end

    def build_type(prod, name)
      # have to put it as mead.usersys, instead of APP_CONFIG
      # why?????????/
      Net::HTTP.get('mead.usersys.redhat.com',
                    "/mead-scheduler/rest/package/#{prod}/#{name}/type")
    end

	  def is_scl_package?(prod, name)
	    ans = ''
	    begin
	      Net::HTTP.start('mead.usersys.redhat.com') do |http|
	        resp = http.get("/mead-scheduler/rest/package/#{prod}/#{name}/scl")
	        ans = resp.body
	      end
	      ans == 'YES'
	    rescue
	      true
	    end
	  end

    def get_nvr_from_bridge(tag, pkg_name)
      uri = URI.parse(URI.encode("#{APP_CONFIG['mead_scheduler']}/mead-brewbridge/pkg/latest/#{tag}/#{pkg_name}"))
      res = Net::HTTP.get_response(uri)
      (res.code == '200' && !res.body.include?('ERROR')) ? res.body : nil
    end
	end
end