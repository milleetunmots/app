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

    return self if Events::TextMessage.automatic_message_sent?(parent: @parent, key: KEY, since: 1.day.ago)

    supporter = @parent.current_child&.child_support&.supporter
    return self unless supporter

    unless supporter.aircall_phone_number
      @errors << 'Child supporter has no aircall_phone_number'
      return self
    end

    send_reply
    self
  end

  private

  def send_reply
    bundle = Media::TextMessagesBundle.find_automatic(name: NAME, key: KEY)
    return report_missing_bundle unless bundle

    service = ProgramAutomaticMessageService.new(
      @date.strftime('%d-%m-%Y'),
      @date.strftime('%H:%M'),
      ["parent.#{@parent.id}"],
      bundle.body1,
      bundle.rcs_media_id_to_send(1),
      link_id(bundle),
      automatic_message_key: KEY
    ).call
    @errors << "Response message not sent to #{@parent.first_name} #{@parent.last_name} : #{service.errors.join(' - ')}" if service.errors.any?
  end

  def report_missing_bundle
    @errors << "Trio introuvable : « #{NAME} » (clé #{KEY}), message non envoyé"
  end

  def link_id(bundle)
    RedirectionTarget.find_or_create_by(medium_id: bundle.link1_id).id if bundle.link1_id
  end
end
