# Tâche de suivi d'un envoi bloqué : assignée au compte de l'équipe tech, avec
# l'auteur du message en reporter pour qu'il la retrouve dans ses tâches.
# Visible par l'auteur : elle ne révèle ni le contrôle déclenché ni les valeurs
# détectées, comme BlockedSendAttempt::SendGuard::BLOCKED_MESSAGE.
class BlockedSendAttempt::CreateTaskService

  TITLE = 'Envoi bloqué à vérifier'.freeze

  attr_reader :errors, :task

  def initialize(attempt:)
    @attempt = attempt
    @errors = []
  end

  # Un compte assigné introuvable n'empêche pas la tâche : elle reste visible
  # dans « Toutes » et l'auteur garde son lien.
  def call
    assignee = find_assignee
    @task = Task.create(
      title: TITLE,
      description: description,
      due_date: Time.zone.today,
      reporter_id: @attempt.admin_user_id,
      assignee: assignee,
      related: @attempt
    )
    return self if @task.persisted?

    @errors << {
      message: "La tâche de l'envoi bloqué n'a pas pu être créée",
      context: { blocked_send_attempt_id: @attempt.id, errors: @task.errors.full_messages }
    }
    @task = nil
    self
  end

  private

  def find_assignee
    email = ENV.fetch('BLOCKED_SEND_ASSIGNEE_EMAIL', nil)
    assignee = AdminUser.find_by(email: email) if email.present?
    return assignee if assignee

    @errors << {
      message: 'Le compte assigné aux envois bloqués est introuvable',
      context: { blocked_send_attempt_id: @attempt.id, email: email }
    }
    nil
  end

  # La description est rendue telle quelle (TaskDecorator#display_description) :
  # le message saisi par l'auteur est échappé, seuls les sauts de ligne sont gardés.
  def description
    ERB::Util.html_escape(@attempt.message_body).to_str.gsub("\n", '<br>')
  end
end
