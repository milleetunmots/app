class SpotHit::SendRcsService

  include JsonResponseConcern
  include SpotHit::Recipients

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
      restrict_recipients_to_safe_numbers!
      return if recipient_variables.empty?
    end

    if personalized_recipients?
      # form params: custom_list_with_data[phone][variable]=value
      # same format as SMS with data but with custom_list_with_data instead of destinataires
      recipient_variables.each do |parent_id, variables|
        phone_number = phone_numbers_by_parent_id[parent_id]
        next if phone_number.blank?

        variables.each do |key, value|
          @form["custom_list_with_data[#{phone_number}][#{key}]"] = value
        end
      end
    else
      @form['custom_list[]'] = recipient_phone_numbers
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

  def create_events(rcs_id)
    parents_by_id = Parent.where(id: recipient_variables.keys).index_by(&:id)

    recipient_variables.each do |parent_id, keys|
      parent = parents_by_id[parent_id]
      @errors << "Erreur lors de la création de l'event d'envoi de rcs : parent #{parent_id} introuvable." and next if parent.nil?

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
end
