class Parent::SendScheduledCallReminderService

  attr_reader :errors

  def initialize(parent_id:, scheduled_call_id:, message:)
    @errors = []
    @parent = Parent.find_by(id: parent_id)
    @scheduled_call = ScheduledCall.find_by(id: scheduled_call_id)
    @message = message
  end

  def call
    unless @parent
      @errors << { service: 'SendScheduledCallReminderDayBeforeService', message: "Aucun parent n'a été trouvé" }
      return self
    end
    unless @scheduled_call
      @errors << { service: 'SendScheduledCallReminderDayBeforeService', message: "Aucun RDV n'a été trouvé" }
      return self
    end
    if @scheduled_call.canceled?
      @errors << { service: 'SendScheduledCallReminderDayBeforeService', message: 'Le RDV a été annulé' }
      return self
    end
    service = ProgramMessageService.new(
      Time.zone.now.strftime('%d-%m-%Y'),
      Time.zone.now.strftime('%H:%M'),
      ["parent.#{@parent.id}"],
      @message
    ).call
    @errors << { service: 'SendScheduledCallReminderDayBeforeService', message: 'La programmation du message a échoué', errors: service.errors } if service.errors.any?
    self
  end
end
