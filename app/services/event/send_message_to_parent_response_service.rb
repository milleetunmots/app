class Event::SendMessageToParentResponseService

  # Send message to ask parent to send message directly to supporter aircall phone number

  attr_reader :errors

  MESSAGE = "1001mots: Ce numéro ne peut pas recevoir de SMS. Pour nous contacter, merci d'envoyer vos messages directement à".freeze

  def initialize(parsed_phone)
    @parsed_phone = parsed_phone
    @errors = []
    @message = "#{MESSAGE} {PRENOM_APPELANTE} au {NUMERO_AIRCALL_APPELANTE}. Merci!"
    @date = Time.zone.now
    @parent = Parent.find_by(phone_number: parsed_phone)
  end

  def call
    unless @parent
      @errors << 'Parent not found'
      return self
    end

    return self if @parent.message_already_sent?(MESSAGE)

    supporter = @parent.current_child&.child_support&.supporter
    return self unless supporter

    unless supporter.aircall_phone_number
      @errors << 'Child supporter has no aircall_phone_number'
      return self
    end

    service = ProgramMessageService.new(
      @date.strftime('%d-%m-%Y'),
      @date.strftime('%H:%M'),
      ["parent.#{@parent.id}"],
      @message
    ).call
    @errors << "Response message not sent to #{@parent.first_name} #{@parent.last_name} : #{service.errors.join(' - ')}" if service.errors.any?
    self
  end
end
