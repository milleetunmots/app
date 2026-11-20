class Child::ProgramNotSupportedMessageService

  NAME = 'Message de non-accompagnement'.freeze
  KEY = 'non_accompagnement'.freeze

  attr_reader :errors

  def initialize(child)
    @child = child
    @errors = []
  end

  def call
    bundle = Media::TextMessagesBundle.find_automatic(name: NAME, key: KEY)
    return add_error('Trio introuvable') unless bundle
    return add_error("Le trio n'a pas de lien") unless bundle.link1_id

    program_message(bundle)
    self
  end

  private

  def add_error(reason)
    @errors << "#{reason} : « #{NAME} » (clé #{KEY}), message non envoyé"
    self
  end

  def program_message(bundle)
    link_id = RedirectionTarget.find_or_create_by(medium_id: bundle.link1_id).id
    service = ProgramMessageService.new(
      Time.zone.now.next_day(3).strftime('%d-%m-%Y'), '12:30', ["child.#{@child.id}"], bundle.body1,
      bundle.rcs_media_id_to_send(1), link_id, false, nil, nil, ['not_supported']
    ).call
    @errors.concat(service.errors)
  end
end
