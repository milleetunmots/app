class Task::CreateAutomaticTaskService

  # assignee_email : e-mail de l'AdminUser assigné, chef(fe) de projet opération par défaut.
  def initialize(title:, description:, due_date: Time.zone.today, assignee_email: ENV.fetch('OPERATION_PROJECT_MANAGER_EMAIL', nil))
    @title = title
    @description = description
    @assignee_email = assignee_email
    @assignee = AdminUser.find_by(email: assignee_email) if assignee_email.present?
    @due_date = due_date
  end

  def call
    unless @assignee
      Rollbar.error("L'utilisateur assigné à la tâche automatique est introuvable", email: @assignee_email, title: @title)
      return self
    end

    @task = Task.create(
      assignee_id: @assignee.id,
      title: @title,
      description: @description,
      due_date: @due_date
    )
    self
  end
end
