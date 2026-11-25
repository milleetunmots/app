require 'rails_helper'

RSpec.describe Child::ProgramRegistrationMessagesService do
  def registration_bundle(name, key, body = "Texte du trio #{name}")
    FactoryBot.create(:media_text_messages_bundle, name: name, body1: body, body2: nil, body3: nil).update_column(:key, key)
  end

  let(:lea) { FactoryBot.create(:child, first_name: 'Léa', group: FactoryBot.create(:group), group_status: 'active') }
  let(:paul) { lea.parent1 }

  around { |example| travel_to(Time.zone.parse('2027-03-02 10:00')) { example.run } }

  [
    [:welcome, "Bienvenue (hors période d'été)", 'bienvenue'],
    [:welcome_summer, "Bienvenue (période d'été)", 'bienvenue_ete'],
    [:eval25, 'Inscription confirmée (eval25)', 'inscription_confirmee_eval25']
  ].each do |message, name, key|
    it "envoie immédiatement au parent 1 le texte du trio « #{name} »" do
      registration_bundle(name, key)
      expect(ProgramAutomaticMessageService).to receive(:new).with(
        '02-03-2027', '10:00', ["parent.#{paul.id}"], "Texte du trio #{name}", nil, nil,
        automatic_message_key: key, recipient_variables: { paul.id => {} }, all_recipients: true
      ).and_call_original

      expect(described_class.new(paul).call(message).errors).to be_empty
    end
  end

  it "envoie l'invitation au questionnaire avec les prénoms de la fratrie et le lien du parent" do
    FactoryBot.create(:child, first_name: 'Hugo', parent1: paul, group_status: 'waiting')
    registration_bundle('Invitation à remplir le questionnaire', 'invitation_questionnaire')
    expect(ProgramAutomaticMessageService).to receive(:new).with(
      '02-03-2027', '18:00', ["parent.#{paul.id}"], 'Texte du trio Invitation à remplir le questionnaire', nil, nil,
      automatic_message_key: 'invitation_questionnaire',
      recipient_variables: { paul.id => { 'PRENOMS_ENFANTS' => 'Léa et Hugo', 'LIEN_QUESTIONNAIRE' => a_string_including(paul.security_token) } },
      all_recipients: true
    ).and_call_original

    described_class.new(paul).send_questionnaire(at: Time.zone.now.change(hour: 18))
  end

  [
    [:instagram, 'Invitation à suivre Instagram', 'invitation_instagram', '05-03-2027 18:00', { 'PRENOM_ENFANT' => 'Hugo' }],
    [:instagram_caf, 'Invitation à suivre Instagram (CAF)', 'invitation_instagram_caf', '05-03-2027 18:00', { 'PRENOM_ENFANT' => 'Hugo' }],
    [:late_support, 'Démarrage tardif', 'demarrage_tardif', '03-03-2027 12:30', {}]
  ].each do |message, name, key, moment, variables|
    it "programme le #{moment} le texte du trio « #{name} »" do
      registration_bundle(name, key)
      at = Time.zone.parse(moment)
      date, hour = moment.split
      expect(ProgramAutomaticMessageService).to receive(:new).with(
        date, hour, ["parent.#{paul.id}"], "Texte du trio #{name}", nil, nil,
        automatic_message_key: key, recipient_variables: { paul.id => variables }, all_recipients: true
      ).and_call_original

      described_class.new(paul).call(message, at: at, variables: variables)
    end
  end

  describe 'mêmes destinataires qu\'aujourd\'hui' do
    def campaigns_count
      WebMock::RequestRegistry.instance.requested_signatures.hash.keys.count { |signature| signature.uri.path.start_with?('/api/envoyer/') }
    end

    before { registration_bundle("Bienvenue (hors période d'été)", 'bienvenue') }

    {
      "Hugo est sur liste d'attente" => ->(parent) { FactoryBot.create(:child, first_name: 'Hugo', parent1: parent, group_status: 'waiting') },
      "la fiche de Léa, sœur de Hugo, n'est plus valide" => ->(parent) { parent.parent1_children.first.update_column(:first_name, '') },
      'Paul a répondu STOP : « contacter parent 1 » est décoché sur la fiche de Léa' =>
        ->(parent) { parent.parent1_children.first.update_column(:should_contact_parent1, false) }
    }.each do |situation, setup|
      it "programme la bienvenue pour Paul quand #{situation}" do
        setup.call(paul)
        WebMock::RequestRegistry.instance.reset!

        service = described_class.new(paul).call(:welcome)

        expect(service.errors).to be_empty
        expect(campaigns_count).to eq(1)
      end
    end
  end

  it "n'envoie rien et signale le trio de bienvenue introuvable" do
    expect(ProgramAutomaticMessageService).not_to receive(:new)

    service = described_class.new(paul).call(:welcome)

    expect(service.errors).to eq(["Trio introuvable : « Bienvenue (hors période d'été) » (clé bienvenue), message non envoyé"])
  end
end
