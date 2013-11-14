require 'json'
class ErrataCheckController < ApplicationController

  def sync
    nvrs = JSON.parse(params["nvrs"])

    # advisory = params['advisory']

    render :text => "OK", :status => 202

    task = Task.first(:conditions => ["advisory = ?", params[:advisory]])

    nvrs.each do |nvr|

      if nvr.start_with? 'sunws-metadata-2.0-api'
        # TODO: temporary hack to get the correct package name for sunws
        pac_name = 'sunws-metadata-2.0-api'
      else
        pac_name = nvr.gsub(/-[0-9].*/, '')
      end

      package = Package.first(:conditions => ["task_id = ? and name = ?", task.id, pac_name])
      if package
        package.in_errata = nvr
        package.save
      end
    end
  end

  def sync_bz
    bz_bugs = JSON.parse(params["bz_bugs"])
    render :text => "OK", :status => 202

    bz_bugs.each do |bug|
      bz_bug = BzBug.first(:conditions => ["bz_id = ?", bug.to_s])
      if bz_bug:
        bz_bug.is_in_errata = "YES"
        bz_bug.save
      end
    end
  end

  def sync_rpmdiffs

    rpmdiffs = JSON.parse(params['rpmdiffs'])

    task = Task.first(:conditions => ["advisory = ?", params[:advisory]])

    rpmdiffs.each do |rpmdiff|
        nvr = rpmdiff['nvr']
        pac_name = nvr.gsub(/-[0-9].*/, '')
        package = Package.first(:conditions => ["task_id = ? and name = ?", task.id, pac_name])

        if package
          package.rpmdiff_status = rpmdiff['status']
          package.rpmdiff_id = rpmdiff['id']
          package.save
        end

    end
    render :text => "OK", :status => 202
  end
end
