# Signale un envoi bloqué : tâche de suivi pour son auteur, puis alerte de
# l'équipe tech. Appelé par le guard pendant l'envoi, ou après coup quand
# l'envoi a eu lieu dans une transaction annulée (création d'atelier).
class BlockedSendAttempt::ReportService

  attr_reader :errors, :task

  # attempts : tentatives « à traiter » d'un même envoi, une par kind détecté.
  def initialize(attempts:, recipients_count: nil, recipient_parent_id: nil)
    @attempts = attempts
    @recipients_count = recipients_count
    @recipient_parent_id = recipient_parent_id
    @errors = []
  end

  def call
    return self if @attempts.empty?

    @task = open_task || create_task
    # Une seule alerte par envoi, et seulement à sa première tentative : un
    # renvoi à l'identique ou un retry Sidekiq retrouve les tentatives existantes.
    notify_slack if @attempts.any?(&:previously_new_record?)
    self
  end

  private

  # Un renvoi à l'identique retrouve ses tentatives par déduplication : on
  # rattache l'auteur à la tâche déjà ouverte au lieu d'en créer une.
  def open_task
    Task.kept.todo.find_by(related: @attempts)
  end

  # Pas d'auteur (envoi automatique) : personne à prévenir.
  def create_task
    return unless @attempts.any?(&:previously_new_record?)
    return if @attempts.first.admin_user_id.nil?

    service = BlockedSendAttempt::CreateTaskService.new(attempt: @attempts.first, recipients_count: @recipients_count, recipient_parent_id: @recipient_parent_id).call
    @errors.concat(service.errors)
    service.task
  end

  def notify_slack
    service = BlockedSendAttempt::NotifySlackService.new(attempts: @attempts, recipients_count: @recipients_count, task: @task).call
    @errors.concat(service.errors)
  end
end
