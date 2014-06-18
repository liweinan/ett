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

    all_packages = Package.all(:include => :rpm_diffs,
                               :conditions => ["task_id = ?", task.id])

    RpmDiff.transaction do
      nvrs.each do |nvr|

        pac_name = parse_nvr(nvr)[:name]

        package = all_packages.select {|pkg| pkg.name == pac_name}

        unless package.empty?
          package = package[0]
          rpm_diff = package.get_rpmdiff(distro)
          rpm_diff.nvr_in_errata = nvr
          if package.nvr_in_brew(distro) == nvr
            in_errata = 'YES'
          else
            in_errata = 'NO'
          end
          rpm_diff.in_errata = in_errata
          rpm_diff.save
          all_packages.delete(package)
        end
      end

      # for all the packages not in the errata, make sure to indicate that their
      # nvrs are not in the errata.
      all_packages.each do |pkg|
        rpm_diff = pkg.get_rpmdiff(distro)
        rpm_diff.in_errata = 'NO'
        # rpm_diff.save
      end
    end
  end

  def sync_bz
    bz_bugs = JSON.parse(params['bz_bugs'])
    render :text => 'OK', :status => 202
    BzBug.transaction do
      bz_bugs.each do |bug|
        bz_bug = BzBug.first(:conditions => ['bz_id = ?', bug.to_s])
        if bz_bug
          bz_bug.is_in_errata = 'YES'
          bz_bug.save
        end
      end
    end
  end

  def sync_rpmdiffs
    rpmdiffs = JSON.parse(params['rpmdiffs'])

    os_adv_tag = OsAdvisoryTag.first(:conditions => ['advisory = ?',
                                                     params[:advisory]])
    task = os_adv_tag.task
    distro = os_adv_tag.os_arch

    all_packages = Package.all(:include => [:rpm_diffs, :brew_nvrs],
                               :conditions => ["task_id = ?", task.id])

    RpmDiff.transaction do
      rpmdiffs.each do |rpmdiff|
        nvr = rpmdiff['nvr']
        pac_name = parse_nvr(nvr)[:name]
        package = all_packages.select {|pkg| pkg.name == pac_name}

        unless package.empty?
          package = package[0]
          rpmdiff_pac = package.get_rpmdiff(distro)
          if package.nvr_in_brew(distro) == rpmdiff['nvr']
            # there are sometimes a few rpmdiffs running for the same nvr. We
            # just take the decision to pick the rpmdiff with the largest
            # number, which means its the rpmdiff who ran the latest.
            if rpmdiff_pac.rpmdiff_status.nil? ||
               rpmdiff['status'].to_i > rpmdiff_pac.rpmdiff_status.to_i

              rpmdiff_pac.rpmdiff_status = rpmdiff['status']
              rpmdiff_pac.rpmdiff_id = rpmdiff['id']
              rpmdiff_pac.save
            end
          end
        end
      end
    end
    render :text => 'OK', :status => 202
  end

  private
  def parse_nvr(nvr)
    ret = {}
    p2 = nvr.rindex('-')
    p1 = nvr.rindex('-', p2 - 1)
    ret[:release] = nvr[(p2 + 1)..-1]
    ret[:version] = nvr[(p1 + 1)...p2]
    ret[:name] = nvr[0...p1]

    ret
  end
end
