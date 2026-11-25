require 'rails_helper'

RSpec.describe Child::SendInitialFormSmsJob do
  let(:paul) { FactoryBot.create(:child, first_name: 'Léa', group_status: 'waiting').parent1 }

  before do
    FactoryBot.create(:media_text_messages_bundle, name: 'Invitation à remplir le questionnaire', body1: 'Questionnaire : {LIEN_QUESTIONNAIRE}', body2: nil, body3: nil)
              .update_column(:key, 'invitation_questionnaire')
  end

  it "envoie l'invitation au questionnaire d'après son trio, valeurs calculées à l'envoi" do
    expect(ProgramAutomaticMessageService).to receive(:new).with(
      anything, anything, ["parent.#{paul.id}"], 'Questionnaire : {LIEN_QUESTIONNAIRE}', nil, nil,
      automatic_message_key: 'invitation_questionnaire',
      recipient_variables: { paul.id => { 'PRENOMS_ENFANTS' => 'Léa', 'LIEN_QUESTIONNAIRE' => a_string_including(paul.security_token) } },
      all_recipients: true
    ).and_call_original

    described_class.perform_now(paul.id)
  end

  it "traite un job programmé avant le passage aux trios, dont le second argument est l'ancien texte" do
    expect(ProgramAutomaticMessageService).to receive(:new).with(
      anything, anything, ["parent.#{paul.id}"], 'Questionnaire : {LIEN_QUESTIONNAIRE}', nil, nil,
      automatic_message_key: 'invitation_questionnaire', recipient_variables: anything, all_recipients: true
    ).and_call_original

    described_class.perform_now(paul.id, 'Bonjour, merci pour votre inscription…')
  end
end
