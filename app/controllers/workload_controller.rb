class WorkloadController < ApplicationController

  def show
    @wl = WeeklyWorkload.find(params[:id])
  end

  # This method needs to be run by cron in a weekly basis
  def generate_weekly_workload
    Package.transaction do
      tasks = Task.all
      tasks.each do |task|
        current_date = Date.today

        if !params[:from].blank?
          current_date = Date.parse(params[:from]) # format: 2012-1-1
        end

        # Define the scope of current week.
        begin_of_current_week = current_date.at_beginning_of_week.to_datetime
        end_of_current_week = current_date.at_end_of_week.to_datetime

        # Find the package that is updated to a "finished status" in current week.
        packages = Package.find_by_sql(["select * from packages where task_id=? and status_id IN (select id from statuses where is_finish_state='Yes') and updated_at >= ? and updated_at <= ?", task.id, begin_of_current_week, end_of_current_week])

        # The candidates are the packages that need to be calucated into weekly workload.
        candidates = []

        # The logic to search for candidates.
        packages.each do |package|
          # search for changelog, to see if the package has statuses changed during this week.
          cnt = Changelog.count_by_sql(["select * from changelogs where package_id=? and category='UPDATE' and 'references'='status' and changed_at >= ? and changed_at <= ?", package.id, begin_of_current_week, end_of_current_week])
          unless cnt.blank?
            candidates << package
          end
        end

        # If a cron job is run multiple times during a week, we need to destroy the older result and replace it with the newer result.
        wl = WeeklyWorkload.find(:first, :conditions => ["start_of_week=? and end_of_week=? and task_id=?", begin_of_current_week, end_of_current_week, task.id])
        unless wl.blank?
          wl.destroy
        end

        # Generate a new weekly workload report.
        wl = WeeklyWorkload.new
        wl.start_of_week = begin_of_current_week
        wl.end_of_week = end_of_current_week
        wl.package_count = candidates.size
        wl.task_id = task.id
        wl.save

        candidates.each do |package|
          ps = PackageStat.new
          ps.weekly_workload_id = wl.id
          ps.package_id = package.id
          ps.user_id = package.user_id
          ps.save

          # Collect data of auto log entires
          entries = AutoLogEntry.all(:conditions => ["package_id = ? and start_time >= ? and end_time <= ?", package.id, begin_of_current_week, end_of_current_week])
          entries.each do |entry|
            #sum up the time spent on each status during this week
            ls = StatusStat.find(:first, :conditions => ["package_stat_id=? and status_id=?", ps.id, entry.status_id])

            if ls.blank?
              ls = StatusStat.new
              ls.package_stat_id = ps.id
              ls.status_id = entry.status_id
              ls.user_id = entry.who_id
              ls.minutes += (entry.end_time.to_i - entry.start_time.to_i) / 60
            else
              ls.minutes += (entry.end_time.to_i - entry.start_time.to_i) / 60
            end
            ls.save

            asd = AutoSumDetail.find(:first, :conditions => ["weekly_workload_id=? and status_id=?", wl.id, ls.status_id])
            if asd.blank?
              asd = AutoSumDetail.new
              asd.weekly_workload_id = wl.id
              asd.status_id = ls.status_id
            end

            asd.minutes += ls.minutes
            asd.save

            entry.weekly_workload_id = wl.id
            entry.save
          end

          # Deprecated
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

            entry.weekly_workload_id = wl.id
            entry.save

            wl.manual_sum += ws.minutes
            ps.minutes += (entry.end_time.to_i - entry.start_time.to_i) / 60
          end
          ps.save
        end
        wl.save
      end
    end
  end
end
