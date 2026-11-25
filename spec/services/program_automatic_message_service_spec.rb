require 'rails_helper'

RSpec.describe ProgramAutomaticMessageService do
  def program(message, rcs_media_id = nil)
    described_class.new(
      Time.zone.today.strftime('%d-%m-%Y'), '12:30', ["parent.#{parent.id}"], message, rcs_media_id,
      automatic_message_key: 'numero_sans_sms'
    ).call
  end

  let(:parent) { FactoryBot.create(:child, group: FactoryBot.create(:group), group_status: 'active').parent1 }

  around { |example| travel_to(Time.zone.parse('2027-03-02 09:00')) { example.run } }

  it 'enregistre la clé du message automatique sur un message envoyé en SMS' do
    service = program("1001mots : #{'a' * 200}")

    expect(service.errors).to be_empty
    expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms')
    expect(parent.events.text_messages.last.automatic_message_key).to eq('numero_sans_sms')
  end

  it 'enregistre la clé du message automatique sur un message envoyé en RCS basic' do
    service = program('1001mots : Bonjour !')

    expect(service.errors).to be_empty
    expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').with(body: /rcs_type=basic/)
    expect(parent.events.text_messages.last.automatic_message_key).to eq('numero_sans_sms')
  end

  it 'enregistre la clé du message automatique sur un message envoyé en RCS single' do
    service = program("1001mots : #{'a' * 200}", 4522)

    expect(service.errors).to be_empty
    expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').with(body: /media_id=4522/)
    expect(parent.events.text_messages.last.automatic_message_key).to eq('numero_sans_sms')
  end

  it "garde la clé du message automatique dans l'envoi bloqué, pour le rejouer avec elle" do
    previous = ENV.fetch('URL_FILTER_BLOCKING_ENABLED', nil)
    ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'

    service = program('1001mots : Rejoignez-nous sur https://exemple-non-autorise.fr')

    expect(service.errors).not_to be_empty
    expect(BlockedSendAttempt.last.replay_params).to include('automatic_message_key' => 'numero_sans_sms')
  ensure
    ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
  end

  describe 'valeurs propres à chaque famille fournies à l\'envoi' do
    def program_with(message, variables, rcs_media_id = nil)
      described_class.new(
        Time.zone.today.strftime('%d-%m-%Y'), '12:30', ["parent.#{parent.id}"], message, rcs_media_id,
        automatic_message_key: 'invitation_choix_theme', recipient_variables: { parent.id => variables }
      ).call
    end

    def sent_value(variable)
      WebMock::RequestRegistry.instance.requested_signatures.hash.keys
                              .select { |signature| signature.uri.path.start_with?('/api/envoyer/') }
                              .flat_map { |signature| URI.decode_www_form(signature.body) }
                              .find { |key, _| key.end_with?("[#{variable}]") }&.last
    end

    let(:choice_link) { 'https://app.1001mots.org/children_support_modules/12/link?sc=abc' }

    it 'transmet la valeur de la famille avec le modèle du trio quand le message part en RCS single' do
      service = program_with("Choisissez le thème : {LIEN_CHOIX_THEME} #{'a' * 300}", { 'LIEN_CHOIX_THEME' => choice_link }, 4601)

      expect(service.errors).to be_empty
      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').with(body: /media_id=4601/)
      expect(sent_value('LIEN_CHOIX_THEME')).to eq(choice_link)
    end

    it 'transmet la valeur de la famille quand le message part en RCS basic' do
      service = program_with('Choisissez le thème : {LIEN_CHOIX_THEME}', { 'LIEN_CHOIX_THEME' => choice_link })

      expect(service.errors).to be_empty
      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').with(body: /rcs_type=basic/)
      expect(sent_value('LIEN_CHOIX_THEME')).to eq(choice_link)
    end

    it "remplace le prénom de l'enfant courant par celui de l'enfant concerné" do
      parent.current_child.update!(first_name: 'Léa')

      program_with('Un livre pour {PRENOM_ENFANT}', { 'PRENOM_ENFANT' => 'Hugo' })

      expect(sent_value('PRENOM_ENFANT')).to eq('Hugo')
    end

    it 'remplace l\'heure du dernier RDV à venir par celle du RDV qui vient d\'être pris' do
      FactoryBot.create(:scheduled_call, parent: parent, child_support: parent.current_child.child_support, scheduled_at: Time.zone.parse('2027-03-10 14:30'))

      program_with('RDV vers {RDV_CALENDLY_SCHEDULED_AT_HOUR}', { 'RDV_CALENDLY_SCHEDULED_AT_HOUR' => '10:00' })

      expect(sent_value('RDV_CALENDLY_SCHEDULED_AT_HOUR')).to eq('10:00')
    end

    it "garde l'adresse fournie sur plusieurs lignes" do
      program_with("Votre adresse :\n{PARENT_ADDRESS}", { 'PARENT_ADDRESS' => "3 rue des Lilas\n75011 Paris" })

      expect(sent_value('PARENT_ADDRESS')).to eq("3 rue des Lilas\n75011 Paris")
    end

    it "garde les valeurs de la famille dans l'envoi bloqué, pour le rejouer avec elles" do
      previous = ENV.fetch('URL_FILTER_BLOCKING_ENABLED', nil)
      ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'

      program_with('Rejoignez-nous sur https://exemple-non-autorise.fr {LIEN_CHOIX_THEME}', { 'LIEN_CHOIX_THEME' => choice_link })

      expect(BlockedSendAttempt.last.replay_params['recipient_variables']).to eq(parent.id.to_s => { 'LIEN_CHOIX_THEME' => choice_link })
    ensure
      ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
    end
  end

  describe 'tous destinataires, pour les messages d\'inscription' do
    def program_to(recipient_parent, all_recipients:)
      described_class.new(
        Time.zone.today.strftime('%d-%m-%Y'), '12:30', ["parent.#{recipient_parent.id}"], 'Bienvenue !',
        automatic_message_key: 'bienvenue', all_recipients: all_recipients
      ).call
    end

    let(:paul) do
      FactoryBot.create(:child, first_name: 'Léa', group: FactoryBot.create(:group), group_status: 'active').parent1.tap do |parent|
        FactoryBot.create(:child, first_name: 'Hugo', parent1: parent, group_status: 'waiting')
        parent.parent1_children.find_by(first_name: 'Léa').update_column(:first_name, '')
      end
    end

    it "programme le message au parent malgré la fiche invalide d'un autre enfant et un enfant sur liste d'attente" do
      service = program_to(paul, all_recipients: true)

      expect(service.errors).to be_empty
      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end

    it "écarte ce parent sans l'option, comme ProgramMessageService" do
      program_to(paul, all_recipients: false)

      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end

    it "garde l'option dans l'envoi bloqué, pour le rejouer avec elle" do
      previous = ENV.fetch('URL_FILTER_BLOCKING_ENABLED', nil)
      ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'

      described_class.new(
        Time.zone.today.strftime('%d-%m-%Y'), '12:30', ["parent.#{parent.id}"], 'Rejoignez-nous sur https://exemple-non-autorise.fr',
        automatic_message_key: 'bienvenue', all_recipients: true
      ).call

      expect(BlockedSendAttempt.last.replay_params).to include('all_recipients' => true)
    ensure
      ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
    end
  end
end
