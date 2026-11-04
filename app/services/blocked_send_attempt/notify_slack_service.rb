# Alerte l'équipe tech qu'un envoi vient d'être bloqué, dans le canal Slack
# dédié. Contrairement au message affiché à l'auteur, elle nomme le contrôle
# déclenché et les valeurs détectées : le canal est réservé à l'équipe tech.
class BlockedSendAttempt::NotifySlackService

  ALERT_ICON_EMOJI = ':no_entry:'.freeze
  ALERT_USERNAME = 'Alerte envoi bloqué'.freeze

  # Un envoi de masse détecte une valeur par destinataire (lien personnalisé,
  # numéro) : l'alerte en montre quelques-unes, tronquées, sans recopier dans
  # Slack les données de toutes les familles.
  VALUES_LIMIT = 5
  VALUE_MAX_LENGTH = 80

  attr_reader :errors

  # attempts : tentatives d'un même envoi (une par kind détecté).
  def initialize(attempts:, recipients_count: nil, task: nil)
    @attempts = attempts
    @recipients_count = recipients_count
    @task = task
    @errors = []
  end

  def call
    channel = ENV.fetch('SLACK_BLOCKED_SEND_ALERT_CHANNEL', nil)
    if channel.blank?
      @errors << { message: "Le canal Slack des envois bloqués n'est pas configuré", context: { blocked_send_attempt_ids: @attempts.map(&:id) } }
      return self
    end

    service = Slack::PostMessageService.new(
      channel: "##{channel}",
      text: alert_text,
      icon_emoji: ALERT_ICON_EMOJI,
      username: ALERT_USERNAME
    ).call
    service.errors.each do |error|
      @errors << { message: "L'alerte Slack de l'envoi bloqué n'a pas pu être postée", context: { blocked_send_attempt_ids: @attempts.map(&:id), error: error } }
    end
    self
  end

  private

  def alert_text
    [
      '*Envoi bloqué — à vérifier*',
      "*Auteur* : #{author_line}",
      "*Fournisseur* : #{@attempts.first.provider}",
      recipients_line,
      "*Contrôle(s)* : #{@attempts.map { |attempt| BlockedSendAttempt.human_attribute_name("kind.#{attempt.kind}") }.join(', ')}",
      "*Valeurs détectées* : #{values_line}",
      "*Tentative(s)* : #{attempts_links}",
      task_line,
      "_#{Time.current.strftime('%d/%m %H:%M')}_"
    ].compact.join("\n")
  end

  def author_line
    author = @attempts.first.admin_user
    return 'envoi automatique' if author.nil?

    slack_link(author.name) { routes.admin_admin_user_url(id: author.id) }
  end

  def recipients_line
    return if @recipients_count.nil?

    "*Destinataires* : #{@recipients_count} #{@recipients_count == 1 ? 'famille' : 'familles'}"
  end

  def values_line
    values = @attempts.flat_map(&:detected_values).uniq
    listed = values.first(VALUES_LIMIT).map { |value| escape(value.truncate(VALUE_MAX_LENGTH)) }.join(', ')
    extra = values.size - VALUES_LIMIT
    extra.positive? ? "#{listed} et #{extra} autres" : listed
  end

  def attempts_links
    @attempts.map { |attempt| slack_link("n° #{attempt.id}") { routes.admin_blocked_send_attempt_url(id: attempt.id) } }.join(', ')
  end

  def task_line
    return unless @task

    "*Tâche* : #{slack_link("n° #{@task.id}") { routes.admin_task_url(id: @task.id) }}"
  end

  # mrkdwn : `<url|libellé>`. Comme SmsSendRecord::QuotaGuard#slack_link : le
  # libellé est échappé, et l'url construite dans un bloc pour que l'absence de
  # DEFAULT_HOSTNAME retire le lien sans faire échouer l'alerte.
  def slack_link(label)
    url = yield
    "<#{url}|#{escape(label)}>"
  rescue StandardError => e
    @errors << { message: "Un lien de l'alerte Slack n'a pas pu être construit", context: { error: e.message } }
    escape(label)
  end

  # Slack impose d'échapper &, < et > : une valeur détectée qui en contient
  # casserait sinon la mise en forme du message.
  def escape(text)
    text.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
  end

  def routes
    Rails.application.routes.url_helpers
  end
end
