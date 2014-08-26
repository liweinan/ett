require 'net/http'
require 'json'
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def render_changelog(changelog)
    return '' if changelog.blank?

    if changelog.category == Changelog::CATEGORY[:comment]
      Changelog::TEMPLATE[:comment] % [changelog.user.name, link_to("##{Comment.find_by_id(changelog.references).id}", "#comment-#{Comment.find_by_id(changelog.references).id}")]
    elsif changelog.category == Changelog::CATEGORY[:create]
      Changelog::TEMPLATE[:create] % changelog.user.name
    elsif changelog.category == Changelog::CATEGORY[:delete]
      Changelog::TEMPLATE[:delete] % changelog.user.name
    elsif changelog.category == Changelog::CATEGORY[:clone]
      to_package = Package.find(changelog.to_value)
      Changelog::TEMPLATE[:clone] % [changelog.user.name, link_to("#{to_package.name}@#{to_package.task.name}", :controller => :packages, :action => :show, :id => escape_url(to_package.name), :task_id => escape_url(to_package.task.name))]
    elsif changelog.category == Changelog::CATEGORY[:update]
      Changelog::TEMPLATE[:update] % changelog.user.name
    else
      ''
    end

  end

  def display_track_time(min)
    if min < 60
      return pluralize(min, 'minute')
    elsif min < 1440
      hrs = min / 60
      mins = min % 60
      return pluralize(hrs, 'hour') + " " + pluralize(mins, 'minute')
    else
      days = min / 1440
      leftover = min % 1440
      hrs = leftover / 60
      mins = leftover % 60
      time = ""
      time << pluralize(days, 'day')
      if hrs > 0
        time << " " << pluralize(hrs, 'hour')
      end
      if mins > 0
        time << " "<< pluralize(mins, 'minute')
      end
      time
    end
  end

  def display_track_time_in_real_time(time_consumed, time_to_add=0)
    display_track_time(time_consumed + time_to_add)
  end

  def display_tags(tags)
    str = ''
    tags.each do |mark|
      str += mark.key + ' / '
    end
    str
  end

  def log_work_time(pac, worktime)
    Package.transaction do
      pac.time_consumed += convert_worktime(worktime)
      pac.save

      entry = ManualLogEntry.new
      entry.end_time = Time.now
      entry.start_time = Time.at(entry.end_time.to_i - convert_worktime(worktime) * 60)
      entry.who = current_user
      entry.package = pac
      entry.save
    end
  end

  def submit_build(pac, clentry, prod, mode,
                   include_spec_file,
                   include_maven_build_arguments_file)

    bz_bug_structure = {}

    pac.upgrade_bz.each do |bz_bug|
      if bz_bug.os_arch.blank?
        bz_bug_structure['el6'] = bz_bug.bz_id.to_i
      else
        bz_bug_structure[bz_bug.os_arch] = bz_bug.bz_id.to_i
      end
    end

    distros_to_build = []
    pac.task.os_advisory_tags.each { |tag| distros_to_build << tag.os_arch }

    # stupid URI.encode cannot encode the '+' sign
    params_build = "mode=#{mode}&userid=#{pac.user.email.gsub('@redhat.com', '')}" + "&sources=#{url_encode(pac.git_url)}&clentry=#{url_encode(clentry)}&version=#{pac.task.tag_version}&bugs=#{url_encode(bz_bug_structure.to_json)}&distros=#{distros_to_build.join(',')}"
    params_build += "&erratum=" + pac.errata unless pac.errata.blank?

    req = Net::HTTP::Post.new("/mead-scheduler/rest/build/sched/#{prod}/#{pac.name}?" + params_build)

    req_data = {}
    req_data[:spec_file] = pac.spec_file if include_spec_file == "1"
    req_data[:maven_build_arguments] = pac.maven_build_arguments if include_maven_build_arguments_file == "1"

    req.body = req_data.to_json unless req_data.blank?
    req.content_type = 'text/plain' unless req_data.blank?

    uri = URI.parse(URI.encode(APP_CONFIG["mead_scheduler"]))
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end

    case res.code
    when "202"
        "Success: #{res.body}"
    when "400"
        "#{res.body}"
    when "409"
        "409: Rejected, build already scheduled for this package \n #{res.body}"
    else
        "#{res.code} error! \n
        Parameters used: #{params.to_json} \n
        #{res.body}"
    end
  end

  def add_errata(pac, prod)
    pac.add_nvr_and_bugs_to_errata
  end

  def convert_worktime(worktime)
    worktime ||= ""
    worktime = worktime.to_s
    mins = 0
    worktime.split(",").each do |wt|
      wt = wt.strip
      unless wt =~ /^\d+[wdhm]$/
        raise TypeError, "Time format incorrect: #{worktime}"
      end

      amount = wt.scan(/\d+/).join.to_i
      scale = wt[-1].chr

      case scale
        when 'w'
          mins += amount * 7 * 24 * 60
        when 'd'
          mins += amount * 24 * 60
        when 'h'
          mins += amount * 60
        when 'm'
          mins += amount
      end
    end
    mins
  end

  def display_manual_track_time_in_real_time(package)
    if package.time_point == 0
      display_track_time(package.time_consumed)
    else
      display_track_time_in_real_time(package.time_consumed, (Time.now.to_i - package.time_point.to_i)/60)
    end
  end

  def at_zone(time, style='')
    if session[:current_user].blank? || session[:current_user].zone.blank?
      if style.blank?
        time
      else
        time.strftime(style)
      end
    else
      if style.blank?
        session[:current_user].zone.at(time.to_i).strftime("%Y-%m-%d %I:%M%p")
      else
        session[:current_user].zone.at(time.to_i).strftime(style)
      end
    end
  end

end
