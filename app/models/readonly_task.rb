class ReadonlyTask < ActiveRecord::Base
  belongs_to :task

  # move packages found in tasks other than 'task_id' to 'Already Released' if
  # there is a package in 'task_id' that is marked as 'Finished', and have the
  # same versions.
  def self.move_other_packages_to_already_released(task_id)
    task = Task.find(task_id)
    packages = task.packages.all.select {|pkg| pkg.status.name == 'Finished'}
    str = ''
    packages.each do |pkg|
      similar_pkgs = Package.find(:all,
                                 :conditions => ['name = ? and ver = ? and task_id != ? and status_id = ?',
                                                 pkg.name, pkg.ver, pkg.task_id, pkg.status_id])

      unless similar_pkgs.blank?
        similar_pkgs.each do |pkg|
          unless pkg.task.active.nil?
            # status = Status.find(:first, :conditions => ['name = ?', 'Already Released'])
            # pkg.status_id = status.id
            str += pkg.remove_nvr_and_bugs_from_errata.to_s
            str += "\n"
            pkg.save
          end
        end
      end
    end
    str
  end
end
