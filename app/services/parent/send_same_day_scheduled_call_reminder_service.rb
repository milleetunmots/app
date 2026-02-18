class Parent::SendSameDayScheduledCallReminderService

  SCHEDULED_CALL_REMINDER_SAME_DAY = <<~MESSAGE.freeze
    1001mots : Rappel de RDV
    Bonjour,
    Vous avez RDV aujourd’hui avec {PRENOM_ACCOMPAGNANTE}, votre accompagnante. Elle vous appellera vers {RDV_CALENDLY_SCHEDULED_AT_HOUR} sur votre numéro. Elle aura peut-être quelques minutes d’avance ou de retard. Pensez à enregistrer son numéro pour ne pas manquer l’appel : {NUMERO_AIRCALL_ACCOMPAGNANTE}.
    Si vous n'êtes plus disponible, annulez le rdv ici : {RDV_CALENDLY_CANCEL_URL}
    A bientôt !
  MESSAGE

  attr_reader :errors

  def initialize
    @errors = []
    @scheduled_calls = ScheduledCall.scheduled.where(scheduled_at: 2.hours.from_now...3.hours.from_now)
    @recipients = @scheduled_calls.map { |scheduled_call| "parent.#{scheduled_call.parent_id}" }
    @message = SCHEDULED_CALL_REMINDER_SAME_DAY.dup
  end

  def call
    return self if @scheduled_calls.empty?

    service = ProgramMessageService.new(
      Time.zone.now.strftime('%d-%m-%Y'),
      Time.zone.now.hour < 8 ? '08:00' : Time.zone.now.strftime('%H:%M'),
      @recipients,
      @message
    ).call
    @errors << { service: 'SendSameDayScheduledCallReminderService', message: 'La programmation du message a échoué', errors: service.errors } if service.errors.any?
    self
  end
end
