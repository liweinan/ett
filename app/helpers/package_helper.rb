module PackageHelper
  def has_task_and_readonly?(task_id)
    has_task? && Task.readonly?(find_task(task_id))
  end
end