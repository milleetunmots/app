class Child::ProgramRegistrationMessagesService

  BUNDLES = {
    welcome: ["Bienvenue (hors période d'été)", 'bienvenue'],
    welcome_summer: ["Bienvenue (période d'été)", 'bienvenue_ete'],
    eval25: ['Inscription confirmée (eval25)', 'inscription_confirmee_eval25'],
    questionnaire: ['Invitation à remplir le questionnaire', 'invitation_questionnaire'],
    instagram: ['Invitation à suivre Instagram', 'invitation_instagram'],
    instagram_caf: ['Invitation à suivre Instagram (CAF)', 'invitation_instagram_caf'],
    late_support: ['Démarrage tardif', 'demarrage_tardif']
  }.freeze

  attr_reader :errors

  def initialize(parent)
    @parent = parent
    @errors = []
  end

  def call(message, at: Time.zone.now, variables: {})
    name, key = BUNDLES.fetch(message)
    bundle = Media::TextMessagesBundle.find_automatic(name: name, key: key)
    return add_error(Media::TextMessagesBundle.missing_message(name: name, key: key)) unless bundle

    service = ProgramAutomaticMessageService.new(
      at.strftime('%d-%m-%Y'), at.strftime('%H:%M'), ["parent.#{@parent.id}"],
      bundle.body1, bundle.rcs_media_id_to_send(1), bundle.redirection_target_id(1),
      automatic_message_key: key, recipient_variables: { @parent.id => variables }, all_recipients: true
    ).call
    @errors.concat(service.errors)
    self
  end

  def send_questionnaire(at:)
    call(:questionnaire, at: at, variables: {
           'PRENOMS_ENFANTS' => Child.where(parent1_id: @parent.id).order(:id).map(&:first_name).to_sentence(words_connector: ', ', two_words_connector: ' et ', last_word_connector: ' et '),
           'LIEN_QUESTIONNAIRE' => Rails.application.routes.url_helpers.initial_typeform_url(st: @parent.security_token)
         })
  end

  private

  def add_error(message)
    @errors << message
    self
  end
end
