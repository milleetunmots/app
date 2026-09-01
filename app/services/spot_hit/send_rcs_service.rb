class SpotHit::SendRcsService

  include JsonResponseConcern

  URL = URI('https://www.spot-hit.fr/api/envoyer/rcs')

  attr_reader :errors

  def initialize(recipients:, planned_timestamp: Time.zone.now, media_id: nil, fallback_message: nil, basic: false, workshop_id: nil, event_params: {}, replay_params: {}, blocked_send_attempt_id: nil)
    @recipients = recipients
    @sent = false
    @planned_timestamp = planned_timestamp
    @form = {
      'key' => ENV['SPOT_HIT_API_KEY'],
      'rcs_type' => basic ? 'basic' : 'single',
      'agent_id' => ENV['SPOT_HIT_AGENT_ID'],
      'fallback_message' => fallback_message
    }
    @media_id = media_id
    @errors = []
    @message = fallback_message
    @event_params = event_params
    @workshop = Workshop.find_by(id: workshop_id)
    @replay_params = replay_params
    @blocked_send_attempt_id = blocked_send_attempt_id
  end

  def call
    @form.merge!({ 'media_id' => @media_id }) if @media_id.present?
    @form.merge!({ 'rcs_basic_message' => @message }) if @form['rcs_type'] == 'basic'
    send_rcs
    self
  end

  # Vrai dès que Spot-Hit a accepté la campagne. Les erreurs qui suivent (event
  # invalide, parent non résolu, atelier non sauvegardé) n'empêchent pas les
  # messages de partir : `errors` seul ne permet donc pas de savoir si l'envoi a
  # eu lieu, et l'appelant doit s'appuyer sur cet indicateur pour décider de
  # rendre le quota réservé (cf. ProgramMessageService).
  def sent?
    @sent
  end

  protected

  def send_rcs
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

    if Rails.env.development? || ENV['SPOT_HIT_SAFEGUARD'].present?
      @recipients = safeguard_recipients(@recipients)
      return if @recipients.empty?
    end
    if @recipients.first.is_a?(String)
      @form['custom_list[]'] = @recipients
    else
      # form params: custom_list_with_data[phone][variable]=value
      # same format as SMS with data but with custom_list_with_data instead of destinataires
      @recipients.each do |phone, variables|
        variables.each do |key, value|
          @form["custom_list_with_data[#{phone}][#{key}]"] = value
        end
      end
    end
    @form['date'] = Time.zone.now if Time.zone.at(@planned_timestamp).past?
    response = HTTP.post(
      URL,
      form: @form.merge({ 'date' => Time.zone.at(@planned_timestamp).past? ? 1.minute.from_now.strftime('%Y-%m-%d %H:%M:%S') : Time.zone.at(@planned_timestamp).strftime('%Y-%m-%d %H:%M:%S') })
    )
    body = parse_json_response(response)
    if body.is_a?(Hash) && body['success']
      @sent = true
      create_events(body['campaign_id'])
    else
      @errors << "Erreur lors de la programmation de la campagne : #{json_error_message(response, body)}"
    end
  end

  # Les vraies URLs envoyées sont souvent dans les variables destinataires
  # ({URL}, {CALLx_CALENDLY_LINK}…), le message ne contenant que des placeholders.
  def recipient_variable_values
    return [] unless @recipients.is_a?(Hash)

    @recipients.values.flat_map { |variables| variables.respond_to?(:values) ? variables.values : [] }
  end

  def safeguard_recipients(recipients)
    safe_numbers = ENV['SAFE_PHONE_NUMBERS'].to_s.split(',').map(&:strip)
    case recipients
    when Hash  then recipients.select { |phone, _| safe_numbers.include?(phone) }
    when Array then recipients.select { |phone| safe_numbers.include?(phone) }
    else            recipients
    end
  end

  def create_events(rcs_id)
    recipients = @recipients
    if recipients.is_a?(Array)
      recipients = recipients.to_h { |phone| [phone, {}] }
    elsif recipients.is_a?(String)
      recipients = recipients.split(', ').to_h { |phone| [phone, {}] }
    end
    recipients.each do |phone_number, keys|
      parent = resolve_parent(phone_number)
      next unless parent

      event_attributes = {
        related_id: parent.id,
        related_type: 'Parent',
        body: @message.dup,
        spot_hit_rcs_id: rcs_id,
        spot_hit_status: 0,
        type: 'Events::TextMessage',
        occurred_at: Time.at(@planned_timestamp)
      }.merge(@event_params[parent.id] || {})
      keys&.map { |key, value| event_attributes[:body].gsub!("{#{key}}", value.to_s) }
      event = Event.create(event_attributes)
      @errors << "Erreur lors de la création de l'event d'envoi de rcs pour #{parent.phone_number}." if event.errors.any?

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

  def resolve_parent(phone_number)
    parents = Parent.kept.where(phone_number: phone_number)
    if parents.empty?
      @errors << "Impossible d'enregistrer le rcs dans l'historique : Parent non trouvé pour le numéro de téléphone #{phone_number}."
      nil
    else
      parents.first
    end
  end
end
