class Event::SendMessageToParentResponseService

  # Send message to ask parent to send message directly to supporter aircall phone number

  attr_reader :errors

  NAME = 'Numéro qui ne reçoit pas de SMS'.freeze
  KEY = 'numero_sans_sms'.freeze

  def initialize(parsed_phone)
    @parsed_phone = parsed_phone
    @errors = []
    @date = Time.zone.now
    @parent = Parent.find_by(phone_number: parsed_phone)
  end

  def call
    unless @parent
      @errors << 'Parent not found'
      return self
    end

    # Ligne du parent verrouillée jusqu'à l'enregistrement de la réponse : deux SMS simultanés ne passent pas tous deux le contrôle.
    Parent.transaction do
      Parent.lock.find(@parent.id)
      reply_unless_already_sent
    end
    self
  end

  private

  def reply_unless_already_sent
    return if Events::TextMessage.automatic_message_sent?(parent: @parent, key: KEY, since: 1.day.ago)

    supporter = @parent.current_child&.child_support&.supporter
    return unless supporter

    unless supporter.aircall_phone_number
      @errors << 'Child supporter has no aircall_phone_number'
      return
    end

    send_reply
  end

  def send_reply
    bundle = Media::TextMessagesBundle.find_automatic(name: NAME, key: KEY)
    return report_missing_bundle unless bundle

    service = ProgramAutomaticMessageService.new(
      @date.strftime('%d-%m-%Y'),
      @date.strftime('%H:%M'),
      ["parent.#{@parent.id}"],
      bundle.body1,
      bundle.rcs_media_id_to_send(1),
      bundle.redirection_target_id(1),
      automatic_message_key: KEY
    ).call
    @errors << "Response message not sent to #{@parent.first_name} #{@parent.last_name} : #{service.errors.join(' - ')}" if service.errors.any?
  end

  def report_missing_bundle
    @errors << Media::TextMessagesBundle.missing_message(name: NAME, key: KEY)
  end
end
