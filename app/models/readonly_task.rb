# == Schema Information
#
# Table name: readonly_tasks
#
#  id         :integer          not null, primary key
#  task_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

class ReadonlyTask < ActiveRecord::Base
  belongs_to :task

  # move packages found in tasks other than 'task_id' to 'Already Released' if
  # there is a package in 'task_id' that is marked as 'Finished', and have the
  # same versions.
  def self.move_other_packages_to_already_released(task_id)
    task = Task.find(task_id)
    packages = task.packages.all.select {|pkg| pkg.status && pkg.status.name == 'Finished'}
    str = ''
    packages.each do |pkg|
      similar_pkgs = Package.find(:all,
                                 :conditions => ['name = ? and ver = ? and task_id != ? and status_id = ?',
                                                 pkg.name, pkg.ver, pkg.task_id, pkg.status_id])

      status = Status.find(:first, :conditions => ['name = ?', 'Already Released'])
      unless similar_pkgs.blank?
        similar_pkgs.each do |pkg_to_change|
          unless pkg_to_change.task.active.nil?
            main_distro = pkg_to_change.task.primary_os_advisory_tag.os_arch
            if pkg.nvr_in_brew(main_distro) != pkg_to_change.nvr_in_brew(main_distro)
              next
            end
            # only remove packages from their erratas if they are in the same prod
            if pkg.task.prod != pkg_to_change.task.prod
              next
            end
            pkg_to_change.status_id = status.id
            str += pkg_to_change.remove_nvr_and_bugs_from_errata.to_s
            str += "\n"
            pkg_to_change.save
          end
        end
      end
    end
    str
  end
end
