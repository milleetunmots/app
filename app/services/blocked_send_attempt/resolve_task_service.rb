# Clôt la tâche de suivi d'un envoi bloqué une fois l'envoi relancé ou archivé :
# c'est ce qui prévient l'auteur. La ligne ajoutée lui dit si son message est
# parti ou non.
class BlockedSendAttempt::ResolveTaskService

  OUTCOME_LINES = {
    relaunched: 'Relancé le %<date>s : le message a été envoyé.',
    archived: "Non relancé : le message n'a pas été envoyé (archivé le %<date>s)."
  }.freeze

  attr_reader :errors

  # outcome : :relaunched ou :archived. admin_user : super_admin qui a traité
  # l'envoi, nil depuis la console.
  def initialize(attempt:, outcome:, admin_user: nil)
    @attempt = attempt
    @outcome = outcome
    @admin_user = admin_user
    @errors = []
  end

  def call
    task = open_task
    return self unless task

    line = format(OUTCOME_LINES.fetch(@outcome), date: Time.zone.today.strftime('%d/%m/%Y'))
    resolved = task.update(
      status: 'done',
      done_at: Time.zone.today,
      treated_by: @admin_user,
      description: [task.description.presence, line].compact.join('<br><br>')
    )
    return self if resolved

    @errors << {
      message: "La tâche de l'envoi bloqué n'a pas pu être close",
      context: { task_id: task.id, blocked_send_attempt_id: @attempt.id, errors: task.errors.full_messages }
    }
    self
  end

  private

  # La tâche est liée à une seule des tentatives d'un même envoi : relancer ou
  # archiver la tentative sœur doit aussi la clore.
  def open_task
    attempts = [@attempt] + BlockedSendAttempt.same_message_as(@attempt).to_a
    Task.kept.todo.find_by(related: attempts)
  end
end
