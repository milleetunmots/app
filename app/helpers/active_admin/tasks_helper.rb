module ActiveAdmin::TasksHelper
  def url_for_new_task(resource)
    new_admin_task_path(
      task: {
        related_type: resource.model.class,
        related_id: resource.id
      }
    )
  end
end
