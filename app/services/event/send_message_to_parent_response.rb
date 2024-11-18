class Event::SendMessageToParentResponse

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
    if @parent.message_already_sent_in_response?
      @errors << 'Message already sent in response'
      return self
    end

    unless @parent
      @errors << 'Parent not found'
      return self
    end

    supporter = @parent.current_child&.child_support&.supporter
    unless supporter
      @errors << 'Child has no supporter'
      return self
    end

    unless supporter&.aircall_phone_number
      @errors << 'Child supporter has no aircall_phone_number'
      return self
    end

    service = ProgramMessageService.new(
      @date.strftime('%d-%m-%Y'),
      @date.strftime('%H:%M'),
      ["parent.#{@parent.id}"],
      @message
    ).call
    @errors << "Response message not sent to #{@parent.first_name} #{@parent.last_name} (#{service.errors.join(' - '))}"
    self
  end
end
