module PackageHelper
  def has_task_and_readonly?(task_id)
    has_task? && find_task(task_id).read_only_task?
  end
end