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

    def get_bz_update_link(id, oneway, params)
      link = APP_CONFIG['mead_scheduler'] +
             APP_CONFIG['bz_bug_summary_update_url'].gsub('<id>', id).gsub('<oneway>', oneway)

      params.each do |key, value|
        link += "&#{key}=#{URI::encode(value)}"
      end

      link
    end

    # params: key-value of what properties you want to set in that bz_id
    def set_bz_upstream_fields(bz_id, oneway, params)
      uri = URI.parse(URI.encode(APP_CONFIG['mead_scheduler']))
      req = Net::HTTP::Put.new(get_bz_update_link(bz_id, oneway, params))
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
    end

    def send_build_to_scheduler(prod, pac_name, params_build, req_data)
      req = Net::HTTP::Post.new("/mead-scheduler/rest/build/sched/#{prod}/#{pac_name}?" + params_build)
      req.body = req_data.to_json unless req_data.blank?
      req.content_type = 'text/plain' unless req_data.blank?
      uri = URI.parse(URI.encode(APP_CONFIG["mead_scheduler"]))

      res = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(req)
      end

      res
    end
	end
end