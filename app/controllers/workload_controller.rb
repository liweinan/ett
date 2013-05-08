class WorkloadController < ApplicationController

  def generate_weekly_workload
    #brew_tag = BrewTag.find(params[:id])
    #begin_of_current_week = Date.today.at_beginning_of_week.to_datetime
    #end_of_current_week = Date.today.at_end_of_week.to_datetime

    #For test
    brew_tag = BrewTag.find(10)
    begin_of_current_week = Date.new(2012, 5, 2).to_datetime
    end_of_current_week = Date.today.at_end_of_week.to_datetime

    packages = Package.find_by_sql(["select * from packages where label_id=(select id from labels where name='Finished' and global='Y') and updated_at >= ? and updated_at <= ?", begin_of_current_week, end_of_current_week])
    candidates = []

    packages.each do |package|
      # search for changelog, to see if the package has labels changed during this week.
      cnt = Changelog.count_by_sql(["select * from changelogs where package_id=? and category='UPDATE' and 'references'='label' and changed_at >= ? and changed_at <= ?", package.id, begin_of_current_week, end_of_current_week])
      unless cnt.blank?
        candidates << package
      end
    end

    # in case this is a rerun
    wl = WeeklyWorkload.find(:first, :conditions => ["start_of_week = ? and end_of_week = ?", begin_of_current_week, end_of_current_week])

    # or it's the first run
    wl ||= WeeklyWorkload.new
    wl.start_of_week = begin_of_current_week
    wl.end_of_week = end_of_current_week
    wl.package_count = candidates.size
    wl.brew_tag_id = brew_tag.id
    wl.save

    # in case this is a rerun  
    wl.package_stats.each do |ps|
      ps.destroy
    end

    candidates.each do |package|
      ps = PackageStat.new
      ps.workload_id = wl.id
      ps.package_id = package.id
      ps.user_id = package.user_id
      ps.save

      # Collect data of auto log entires
      entries = AutoLogEntry.all(:conditions => ["package_id = ? and start_time >= ? and end_time <= ?", package.id, begin_of_current_week, end_of_current_week])
      entries.each do |entry|
        #sum up the time spent on each label during this week
        ls = LabelStat.find(:first, :conditions => ["package_stat_id=? and label_id=?", ps.id, entry.label_id])

        if ls.blank?
          ls = LabelStat.new
          ls.package_stat_id = ps.id
          ls.label_id = entry.label_id
          ls.user_id = entry.who_id
          ls.minutes += (entry.end_time.to_i - entry.start_time.to_i) / 60
        else
          ls.minutes += (entry.end_time.to_i - entry.start_time.to_i) / 60
        end

        ls.save
      end

      # Collect data of manual log entries
      entries = ManualLogEntry.all(:conditions => ["package_id = ? and start_time >= ? and end_time <= ?", package.id, begin_of_current_week, end_of_current_week])
      entries.each do |entry|
        ws = WorktimeStat.find(:first, :conditions => ["package_stat_id=? and user_id=?", ps.id, entry.who_id])
        if ws.blank?
          ws = WorktimeStat.new
          ws.package_stat_id = ps.id
          ws.user_id = entry.who_id
          ws.minutes += (entry.end_time.to_i - entry.start_time.to_i) / 60
        else
          ws.minutes += (entry.end_time.to_i - entry.start_time.to_i) / 60
        end

        ws.save
      end
    end
  end
end
