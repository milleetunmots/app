require 'rails_helper'

RSpec.describe Child::SendSignUpMessagesService do
  let(:registration_messages) { instance_double(Child::ProgramRegistrationMessagesService, errors: []) }
  let(:lea) { FactoryBot.create(:child, first_name: 'Léa', group_status: 'waiting') }

  around { |example| travel_to(Time.zone.parse('2027-03-02 10:00')) { example.run } }

  before do
    allow(Child::ProgramRegistrationMessagesService).to receive(:new).and_return(registration_messages)
    allow(registration_messages).to receive_messages(call: registration_messages, send_questionnaire: registration_messages)
  end

  it "programme l'invitation au questionnaire à 18 h et Instagram à J+3 pour une inscription d'origine 3" do
    described_class.new(lea, 3).call

    expect(registration_messages).to have_received(:send_questionnaire).with(at: Time.zone.parse('2027-03-02 18:00'))
    expect(registration_messages).to have_received(:call).with(:instagram, at: Time.zone.parse('2027-03-05 18:00'), variables: { 'PRENOM_ENFANT' => 'Léa' })
  end

  it "n'envoie ni bienvenue ni questionnaire pour une inscription refusée" do
    lea.update!(group_status: 'not_supported')

    described_class.new(lea, 3).call

    expect(registration_messages).not_to have_received(:send_questionnaire)
    expect(registration_messages).not_to have_received(:call).with(:eval25)
    expect(registration_messages).not_to have_received(:call).with(:instagram, any_args)
  end

  it "signale à Rollbar un message d'inscription non envoyé" do
    allow(registration_messages).to receive(:errors).and_return(['Trio introuvable'])
    allow(Rollbar).to receive(:error)

    described_class.new(lea, nil).call

    expect(Rollbar).to have_received(:error).with(a_string_including('SMS Instagram', 'Trio introuvable'), child_id: lea.id, parent_id: lea.parent1_id)
  end
end
