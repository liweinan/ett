require 'net/http'
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

  def submit_build(pac, clentry, prod, mode)
    uri = URI.parse(URI.encode(APP_CONFIG["mead_scheduler"]))
    req = Net::HTTP::Put.new("/mead-scheduler-web/rest/build/sched/#{prod}/#{pac.name}")
    params = {:mode => mode, :userid => pac.user.email, :sources => pac.git_url, :clentry => clentry}
    req.set_form_data(params)

    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(req)
    end

    case res.code
    when "202"
        "202: Successfully queued package #{pac.name} for building in prod: #{prod}"
    when "400"
        "400: Bad Request: One of the mandatory paramenters is missing or has an invalid value.\n
        Parameters used:  #{params.to_json} \n
        #{res.body}"
    when "409"
        "409: Rejected, build already scheduled for this package \n #{res.body}"
    else
        "#{res.code} error! \n
        Parameters used: #{params.to_json} \n
        #{res.body}"
    end
  end

  def add_errata(pac, prod)

    unless !pac.status.blank? && pac.status.name == 'Finished'
      "You can only add to Errata when the build is Finished."
    else
        uri = URI.parse(URI.encode(APP_CONFIG["mead_scheduler"]))
        # the errata request is sent to mead-scheduler's rest api:
        req = Net::HTTP::Post.new("/mead-scheduler-web/rest/errata/#{prod}/files")

        # TODO: choose which bugs to send to send to mead scheduler

        # may need to update the names of these two parameters:
        params = {:bugs => pac.errata_related_bz, :nvr => pac.brew}
        req.set_form_data(params)

        res = Net::HTTP.start(uri.host, uri.port) do |http|
          http.request(req)
        end

        # Need to update the error codes when we get word on their values:
        case res.code
        when "202"
            "202: Successfully added package #{pac.name} to Errata"
        when "400"
            "400: Bad Request: One of the mandatory paramenters is missing or has an invalid value.\n
            Parameters used:  #{params.to_json} \n
            #{res.body}"
        when "409"
            "409: Rejected, Errata already submitted for this package \n #{res.body}"
        else
            "#{res.code} error! \n
            Parameters used: #{params.to_json} \n
            #{res.body}"
        end
      end
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
