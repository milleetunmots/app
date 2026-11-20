class Event::SendMessageToParentResponseService

  # Send message to ask parent to send message directly to supporter aircall phone number

  attr_reader :errors

  MESSAGE = "1001mots: Ce numéro ne peut pas recevoir de SMS. Pour nous contacter, merci d'envoyer vos messages directement à".freeze
  KEY = 'numero_sans_sms'.freeze

  def initialize(parsed_phone)
    @parsed_phone = parsed_phone
    @errors = []
    @message = "#{MESSAGE} {PRENOM_ACCOMPAGNANTE} au {NUMERO_AIRCALL_ACCOMPAGNANTE}. Merci!"
    @date = Time.zone.now
    @parent = Parent.find_by(phone_number: parsed_phone)
  end

  def call
    unless @parent
      @errors << 'Parent not found'
      return self
    end

    return self if Events::TextMessage.automatic_message_sent?(parent: @parent, key: KEY, since: 1.day.ago)

    supporter = @parent.current_child&.child_support&.supporter
    return self unless supporter

    unless supporter.aircall_phone_number
      @errors << 'Child supporter has no aircall_phone_number'
      return self
    end

    service = ProgramAutomaticMessageService.new(
      @date.strftime('%d-%m-%Y'),
      @date.strftime('%H:%M'),
      ["parent.#{@parent.id}"],
      @message,
      automatic_message_key: KEY
    ).call
    @errors << "Response message not sent to #{@parent.first_name} #{@parent.last_name} : #{service.errors.join(' - ')}" if service.errors.any?
    self
  end
end
