class Parent::SendNextDayScheduledCallReminderService

  BUNDLE = ['Rappel de RDV — la veille (J-1)', 'rappel_rdv_veille'].freeze

  attr_reader :errors

  def initialize
    @errors = []
    @scheduled_calls = ScheduledCall.scheduled.where(scheduled_at: Date.tomorrow.all_day)
    @recipients = @scheduled_calls.map { |scheduled_call| "parent.#{scheduled_call.parent_id}" }
  end

  def call
    return self if @scheduled_calls.empty?

    bundle = find_bundle
    return self unless bundle

    service = ProgramMessageService.new(
      Time.zone.now.strftime('%d-%m-%Y'),
      Time.zone.now.strftime('%H:%M'),
      @recipients,
      bundle.body1,
      bundle.rcs_media_id_to_send(1),
      link_id(bundle)
    ).call
    @errors << { service: 'SendScheduledCallReminderDayBeforeService', message: 'La programmation du message a échoué', errors: service.errors } if service.errors.any?
    self
  end

  private

  def link_id(bundle)
    RedirectionTarget.find_or_create_by(medium_id: bundle.link1_id).id if bundle.link1_id
  end

  def find_bundle
    name, key = BUNDLE
    bundle = Media::TextMessagesBundle.find_automatic(name: name, key: key)
    @errors << "Trio introuvable : « #{name} » (clé #{key}), message non envoyé" unless bundle
    bundle
  end
end
