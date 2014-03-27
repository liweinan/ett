require 'json'
class ErrataCheckController < ApplicationController

  def sync
    nvrs = JSON.parse(params['nvrs'])

    # advisory = params['advisory']

    render :text => 'OK', :status => 202

    os_adv_tag = OsAdvisoryTag.first(:conditions => ['advisory = ?',
                                                     params[:advisory]])
    task = os_adv_tag.task
    distro = os_adv_tag.os_arch

    nvrs.each do |nvr|

      if nvr.start_with? 'sun-ws-metadata-2.0-api'
        # TODO: temporary hack to get the correct package name for sunws
        pac_name = 'sun-ws-metadata-2.0-api'
      else
        pac_name = nvr.gsub(/-[0-9].*/, '')
      end

      package = Package.first(:conditions => ['task_id = ? and name = ?',
                                              task.id,
                                              pac_name])
      if package
        rpm_diff = package.get_rpmdiff(distro)
        rpm_diff.nvr_in_errata = nvr
        if package.nvr_in_brew(distro) == nvr
          in_errata = 'YES'
        else
          in_errata = 'NO'
        end
        rpm_diff.in_errata = in_errata
        rpm_diff.save
      end
    end
  end

  def sync_bz
    bz_bugs = JSON.parse(params['bz_bugs'])
    render :text => 'OK', :status => 202

    bz_bugs.each do |bug|
      bz_bug = BzBug.first(:conditions => ['bz_id = ?', bug.to_s])
      if bz_bug
        bz_bug.is_in_errata = 'YES'
        bz_bug.save
      end
    end
  end

  def sync_rpmdiffs
    rpmdiffs = JSON.parse(params['rpmdiffs'])

    os_adv_tag = OsAdvisoryTag.first(:conditions => ['advisory = ?',
                                                     params[:advisory]])
    task = os_adv_tag.task
    distro = os_adv_tag.os_arch

    rpmdiffs.each do |rpmdiff|
        nvr = rpmdiff['nvr']
        if nvr.start_with? 'sun-ws-metadata-2.0-api'
          # TODO: temporary hack to get the correct package name for sunws
          pac_name = 'sun-ws-metadata-2.0-api'
        else
          pac_name = nvr.gsub(/-[0-9].*/, '')
        end
        package = Package.first(:conditions => ['task_id = ? and name = ?',
                                                task.id,
                                                pac_name])

        if package
          rpmdiff_pac = package.get_rpmdiff(distro)
          rpmdiff_pac.rpmdiff_status = rpmdiff['status']
          rpmdiff_pac.rpmdiff_id = rpmdiff['id']
          rpmdiff_pac.save
        end
    end
    render :text => 'OK', :status => 202
  end
end
