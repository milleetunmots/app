class SpotHit::SendMessageService

  include JsonResponseConcern
  include SpotHit::Recipients

  attr_reader :errors

  # Vrai dès que Spot-Hit a accepté la campagne. Les erreurs qui suivent (event
  # invalide, parent non résolu, atelier non sauvegardé) n'empêchent pas les
  # messages de partir : `errors` seul ne permet donc pas de savoir si l'envoi a
  # eu lieu, et l'appelant doit s'appuyer sur cet indicateur pour décider de
  # rendre le quota réservé (cf. ProgramMessageService).
  def sent?
    @sent
  end

  def initialize(recipients, planned_timestamp, message, file: nil, workshop_id: nil, event_params: {}, replay_params: {}, blocked_send_attempt_id: nil)
    @planned_timestamp = planned_timestamp
    @sent = false
    @recipients = recipients
    @message = message
    @file = file
    @event_params = event_params
    @errors = []
    @workshop = Workshop.find_by(id: workshop_id)
    @replay_params = replay_params
    @blocked_send_attempt_id = blocked_send_attempt_id
  end

  protected

  def send_message(uri, form)
    if content_guard_enabled?
      guard = BlockedSendAttempt::SendGuard.new(
        @message,
        provider: 'spothit',
        extra_texts: recipient_variable_values,
        replay_params: @replay_params,
        blocked_send_attempt_id: @blocked_send_attempt_id
      )
      if guard.blocked?
        guard.register!
        if guard.block_send?
          @errors << guard.error_message
          return
        end
      end
    end

    return unless recipients_available?

    if Rails.env.development? || ENV['SPOT_HIT_SAFEGUARD'].present?
      restrict_recipients_to_safe_numbers!
      return if recipient_variables.empty?

      form = safeguard(form)
    end

    response = HTTP.post(uri, form: form)
    body = parse_json_response(response)

    if !body.is_a?(Hash) || body.key?('erreurs')
      @errors << "Erreur lors de la programmation de la campagne. [Réponse SPOT_HIT API #{json_error_message(response, body)}]"
    else
      @sent = true
      create_events(body['id'])
    end
  end

  def create_events(message_id)
    parents_by_id = Parent.where(id: recipient_variables.keys).index_by(&:id)

    recipient_variables.each do |parent_id, keys|
      parent = parents_by_id[parent_id]
      @errors << "Erreur lors de la création de l'event d'envoi de message : parent #{parent_id} introuvable." and next if parent.nil?

      event_attributes = {
        related_id: parent.id,
        related_type: 'Parent',
        body: @message.dup,
        spot_hit_message_id: message_id,
        spot_hit_status: 0,
        type: 'Events::TextMessage',
        occurred_at: Time.at(@planned_timestamp)
      }.merge(@event_params[parent.id] || {})
      keys&.map { |key, value| event_attributes[:body].gsub!("{#{key}}", value.to_s) }
      event = Event.create(event_attributes)
      @errors << "Erreur lors de la création de l'event d'envoi de message pour #{parent.phone_number}." if event.errors.any?

      next unless @workshop

      @workshop.workshop_participations.build(
        type: 'Events::WorkshopParticipation',
        related_id: parent.id,
        related_type: 'Parent',
        body: @workshop.name,
        occurred_at: @workshop.workshop_date
      )
    end
    return unless @workshop

    @errors << "Erreur lors de la sauvegarde de l'atelier #{@workshop.name}." unless @workshop.save
  end

  # Seam pour les envois qui n'ont rien à voir avec le contenu destiné aux
  # familles (ex: code 2FA d'un administrateur) : voir SpotHit::SendAdminCodeService.
  def content_guard_enabled?
    true
  end

  def safeguard(form)
    safe_numbers = ENV['SAFE_PHONE_NUMBERS'].to_s.split(',').map(&:strip)
    numbers = []

    if form['destinataires'].present?
      numbers = form['destinataires'].split(', ').select { |num| safe_numbers.include?(num) }
      form['destinataires'] = numbers.join(', ')
    end

    form.each_key do |key|
      res = key.match(/destinataires\[(\+\d+)\]/)
      next if res.nil?

      numbers << res[1] and next if safe_numbers.include?(res[1])

      form.delete(key)
    end
    form
  end
end
