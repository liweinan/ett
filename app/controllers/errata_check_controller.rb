require 'json'
class ErrataCheckController < ApplicationController

  def sync
    nvrs = JSON.parse(params['nvrs'])

    if Rails::VERSION::STRING < "4"
      os_adv_tag = OsAdvisoryTag.first(:conditions => ['advisory = ?',
                                                       params[:advisory]])
    else
      os_adv_tag = OsAdvisoryTag.where('advisory = ?',
                                       params[:advisory]).first
    end

    if os_adv_tag.nil?
      render(:text => 'No tag', :status => 200) and return
    end

    render :text => 'OK', :status => 202

    task = os_adv_tag.task
    distro = os_adv_tag.os_arch

    if Rails::VERSION::STRING < "4"
      all_packages = Package.all(:include => :rpm_diffs,
                                 :conditions => ["task_id = ?", task.id])
    else
      all_packages = Package.where("task_id = ?", task.id).includes(:rpm_diffs)
    end

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
        rpm_diff.save
      end
    end
  end

  def sync_bz
    bz_bugs = JSON.parse(params['bz_bugs'])
    if Rails::VERSION::STRING < "4"
      os_adv_tag = OsAdvisoryTag.find(:first,
                                      :conditions => ['advisory = ?', params['advisory']])
    else
      os_adv_tag = OsAdvisoryTag.where('advisory = ?', params['advisory']).first
    end

    if os_adv_tag.nil?
      render(:text => 'OK', :status => 202) and return
    end

    bzs = BzBug.find_bzs(os_adv_tag.task_id, os_adv_tag.os_arch)

    render :text => 'OK', :status => 202
    BzBug.transaction do
      bz_bugs.each do |bug|
        if Rails::VERSION::STRING < "4"
          bz_bug = BzBug.first(:conditions => ['bz_id = ?', bug.to_s])
        else
          bz_bug = BzBug.where('bz_id = ?', bug.to_s).first
        end

        # find out if bz_bug in our database
        bz_bug_in_errata = bzs.delete(bz_bug)

        unless bz_bug_in_errata.nil?
          bz_bug_in_errata.is_in_errata = 'YES'
          bz_bug_in_errata.save
        end
      end

      # the remaining bzs are not in errata
      bzs.each do |bz|
        bz.is_in_errata = 'NO'
        bz.save
      end
    end
  end

  def sync_rpmdiffs
    rpmdiffs = JSON.parse(params['rpmdiffs'])

    if Rails::VERSION::STRING < "4"
      os_adv_tag = OsAdvisoryTag.first(:conditions => ['advisory = ?',
                                                       params[:advisory]])
    else
      os_adv_tag = OsAdvisoryTag.where('advisory = ?',
                                       params[:advisory]).first
    end

    if os_adv_tag.nil?
      render(:text => 'OK', :status => 202) and return
    end

    task = os_adv_tag.task
    distro = os_adv_tag.os_arch

    if Rails::VERSION::STRING < "4"
      all_packages = Package.all(:include => [:rpm_diffs, :brew_nvrs],
                                 :conditions => ["task_id = ?", task.id])
    else
      all_packages = Package.where("task_id = ?", task.id).includes([:rpm_diffs, :brew_nvrs])
    end

    RpmDiff.transaction do
      rpmdiffs.each do |rpmdiff|
        nvr = rpmdiff['nvr']
        pac_name = parse_nvr(nvr)[:name]
        package = all_packages.select {|pkg| pkg.name == pac_name}

        unless package.empty?
          package = package[0]
          rpmdiff_pac = package.get_rpmdiff(distro)
          if package.nvr_in_brew(distro) == rpmdiff['nvr']
            rpmdiff_pac.rpmdiff_status = rpmdiff['status']
            rpmdiff_pac.rpmdiff_id = rpmdiff['id']
            rpmdiff_pac.save
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
