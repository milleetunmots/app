require 'rails_helper'

RSpec.describe ChildSupport::SendCall0GoalsReminderMessagesService do
  let(:link) { 'https://form.1001mots.org/c0?st=abc' }
  let(:child_support) do
    group = FactoryBot.create(:group, started_at: Date.new(2027, 1, 4))
    child = FactoryBot.create(:child, first_name: 'Léa', group: group, group_status: 'active')
    child.child_support.tap do |support|
      support.update_columns(
        call0_goals_sms: "Bonjour, Voici votre petite mission :\r\nLire une histoire chaque soir\r\nQuand vous aurez essayé, dites-le-moi : #{link}",
        call1_status: 'KO'
      )
    end
  end

  it "envoie le texte du trio de l'appel 0, avec la petite mission et le lien de suivi, à 6 semaines" do
    FactoryBot.create(:media_text_messages_bundle, name: 'Rappel de petite mission — appel 0', body1: 'Texte du trio appel 0', body2: nil, body3: nil)
              .update_column(:key, 'rappel_mission_appel0')
    expect(ProgramAutomaticMessageService).to receive(:new).with(
      '15-02-2027', '12:30', ["parent.#{child_support.parent1.id}"], 'Texte du trio appel 0', nil, nil,
      automatic_message_key: 'rappel_mission_appel0',
      recipient_variables: { child_support.parent1.id => { 'PETITE_MISSION' => 'Lire une histoire chaque soir', 'LIEN_SUIVI_PETITE_MISSION' => link } }
    ).and_call_original

    described_class.new(child_support.current_child.group_id).call
  end

  it "n'envoie rien et signale le trio introuvable" do
    group_id = child_support.current_child.group_id
    expect(ProgramAutomaticMessageService).not_to receive(:new)

    service = described_class.new(group_id).call

    expect(service.errors).to include('Trio introuvable : « Rappel de petite mission — appel 0 » (clé rappel_mission_appel0), message non envoyé')
  end
end
