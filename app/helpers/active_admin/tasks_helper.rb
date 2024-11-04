module ActiveAdmin::TasksHelper

  def url_for_new_task(resource)
    new_admin_task_path(
      task: {
        related_type: resource.model.class,
        related_id: resource.id
      }
    )
  end

  def task_title_collection
    Task::TASK_TITLES_WITH_ASSIGNEE_EMAIL.keys.map do |v|
      [
        Task.human_attribute_name("child_support_task_title.#{v}"),
        v
      ]
    end
  end
end
