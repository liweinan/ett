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
      Changelog::TEMPLATE[:clone] % [changelog.user.name, link_to("#{to_package.name}@#{to_package.brew_tag.name}", :controller => :packages, :action => :show, :id => escape_url(to_package.name), :brew_tag_id => escape_url(to_package.brew_tag.name))]
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

  def display_marks(marks)
    str = ''
    marks.each do |mark|
      str += mark.key + ' / '
    end
    str
  end

  def log_work_time(pac, worktime)
    pac.time_consumed += convert_worktime(worktime)
    pac.save
    #((Time.now.to_i - @package.time_point) / 60)
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
end
