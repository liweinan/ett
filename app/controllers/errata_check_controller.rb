require 'json'
class ErrataCheckController < ApplicationController

  def sync
    nvrs = JSON.parse(params["nvrs"])

    # advisory = params['advisory']

    render :text => "OK", :status => 202

    # TODO: work-around for now
    # TODO: should depend on the advisory number in the future
    task = Task.first(:conditions => ["name = ?", 'jb-eap-6.2.0'])

    nvrs.each do |nvr|
      pac_name = nvr.gsub(/-[0-9].*/, '')
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

    # TODO: work-around for now
    # TODO: should depend on the advisory number in the future
    task = Task.first(:conditions => ["name = ?", 'jb-eap-6.2.0'])

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
