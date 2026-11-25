require 'rails_helper'

RSpec.describe Child::AddToGroupService do
  around { |example| travel_to(Time.zone.parse('2027-03-02 10:00')) { example.run } }

  it "programme le démarrage tardif le lendemain à 12 h 30 quand aucune cohorte n'accueille l'enfant inscrit" do
    FactoryBot.create(:media_text_messages_bundle, name: 'Démarrage tardif', body1: 'Texte du trio Démarrage tardif', body2: nil, body3: nil)
              .update_column(:key, 'demarrage_tardif')
    allow(ProgramAutomaticMessageService).to receive(:new).and_call_original

    lea = FactoryBot.create(:child, first_name: 'Léa', group: nil, group_status: 'waiting')

    expect(ProgramAutomaticMessageService).to have_received(:new).with(
      '03-03-2027', '12:30', ["parent.#{lea.parent1_id}"], 'Texte du trio Démarrage tardif', nil, nil,
      automatic_message_key: 'demarrage_tardif', recipient_variables: { lea.parent1_id => {} }, all_recipients: true
    )
  end

  it "inscrit l'enfant sans message et signale le trio introuvable" do
    allow(Rollbar).to receive(:error)

    lea = FactoryBot.create(:child, first_name: 'Léa', group: nil, group_status: 'waiting')

    expect(lea).to be_persisted
    expect(Rollbar).to have_received(:error).with(a_string_including('Trio introuvable : « Démarrage tardif » (clé demarrage_tardif)'))
  end
end
