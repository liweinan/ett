require 'json'
class ErrataCheckController < ApplicationController

  def sync
    nvrs = JSON.parse(params['nvrs'])

    os_adv_tag = OsAdvisoryTag.first(:conditions => ['advisory = ?',
                                                     params[:advisory]])

    if os_adv_tag.nil?
      render(:text => 'No tag', :status => 200) and return
    end

    render :text => 'OK', :status => 202

    task = os_adv_tag.task
    distro = os_adv_tag.os_arch

    all_packages = Package.all(:include => :rpm_diffs,
                               :conditions => ["task_id = ?", task.id])
    RpmDiff.transaction do
      nvrs.each do |nvr|

        pac_name = parse_nvr(nvr)[:name]

        package = all_packages.select {|pkg| pkg.name == pac_name}

        if package.empty?
          package_prod = task.prod
          # in case the package is SCL. e.g eap7-<package>
          pac_name = pac_name.sub(package_prod + '-', '') if package_prod
          package = all_packages.select {|pkg| pkg.name == pac_name}
        end

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
    os_adv_tag = OsAdvisoryTag.find(:first,
                                    :conditions => ['advisory = ?', params['advisory']])

    if os_adv_tag.nil?
      render(:text => 'OK', :status => 202) and return
    end

    bzs = BzBug.find_bzs(os_adv_tag.task_id, os_adv_tag.os_arch)

    render :text => 'OK', :status => 202
    BzBug.transaction do
      bz_bugs.each do |bug|
        bz_bug_in_errata = find_bz(bzs, bug.to_s)
        if !bz_bug_in_errata.nil?
          bzs.reject! { |bz| bz.bz_id == bug.to_s }
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

  def find_bz(bz_list, bz_id)
    bz_list.each do |bz|
      return bz if bz.bz_id == bz_id
    end

    return nil
  end


  def sync_rpmdiffs
    rpmdiffs = JSON.parse(params['rpmdiffs'])

    os_adv_tag = OsAdvisoryTag.first(:conditions => ['advisory = ?',
                                                     params[:advisory]])

    if os_adv_tag.nil?
      render(:text => 'OK', :status => 202) and return
    end

    task = os_adv_tag.task
    distro = os_adv_tag.os_arch

    all_packages = Package.all(:include => [:rpm_diffs, :brew_nvrs],
                               :conditions => ["task_id = ?", task.id])

    RpmDiff.transaction do
      rpmdiffs.each do |rpmdiff|
        nvr = rpmdiff['nvr']
        pac_name = parse_nvr(nvr)[:name]
        package = all_packages.select {|pkg| pkg.name == pac_name}

        if package.empty?
          package_prod = task.prod
          # in case the package is SCL. e.g eap7-<package>
          pac_name = pac_name.sub(package_prod + '-', '') if package_prod
          package = all_packages.select {|pkg| pkg.name == pac_name}
        end

        unless package.empty?
          package = package[0]
          rpmdiff_pac = package.get_rpmdiff(distro)
          if package.nvr_in_brew(distro, false) == rpmdiff['nvr']
            rpmdiff_pac.rpmdiff_status = rpmdiff['status']
            rpmdiff_pac.rpmdiff_id = rpmdiff['id']
            rpmdiff_pac.save
          end
        end
      end
    end
    render :text => 'OK', :status => 202
  end

  def close_task_errata
    task_to_close = params[:task]

    task = Task.find_by_name(task_to_close)
    unless task.nil?
      task.frozen_state = "1"
      task.active = "0"
      task.save
      result = ''
      unless Task.readonly?(task)
        result = ReadonlyTask.move_other_packages_to_already_released(task.id)
        rt = ReadonlyTask.new
        rt.task_id = task.id
        rt.save
      end
      render :text => result, :status => 202
    else
      redner :text => "Task not found", :status => 404
    end

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
