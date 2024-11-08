class Task::CreateAutomaticTaskService

  def initialize(title:, description:, due_date: Time.zone.today)
    @title = title
    @description = description
    @operation_project_manager = AdminUser.find_by(email: ENV['OPERATION_PROJECT_MANAGER_EMAIL'])
    @due_date = due_date
  end

  def call
    unless @operation_project_manager
      Rollbar.error("L'utilisateur 'chef(fe) de projet opération' est introuvable")
      return self
    end

    @task = Task.create(
      assignee_id: @operation_project_manager.id,
      title: @title,
      description: @description,
      due_date: @due_date
    )
    self
  end
end
