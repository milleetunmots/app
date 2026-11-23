require 'rails_helper'

RSpec.describe ChildrenSupportModule::SendReminder do
  def reminder_bundle(name, key)
    FactoryBot.create(:media_text_messages_bundle, name: name, body1: "Texte du trio #{name}", body2: nil, body3: nil).update_column(:key, key)
  end

  let(:child) { FactoryBot.create(:child, first_name: 'Hugo', group: FactoryBot.create(:group), group_status: 'active', should_contact_parent1: true) }
  let(:children_support_module) { FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: nil) }
  let(:reminder_date) { Time.zone.today.next_day(2) }

  [
    [false, 'Relance du choix de thème', 'relance_choix_theme'],
    [true, 'Relance de dernière chance', 'relance_derniere_chance']
  ].each do |second_reminder, name, key|
    it "envoie à 12 h 30 le texte du trio « #{name} », avec le lien de choix et le prénom de l'enfant concerné" do
      reminder_bundle(name, key)
      expect(ProgramAutomaticMessageService).to receive(:new).with(
        reminder_date, '12:30', ["parent.#{child.parent1_id}"], "Texte du trio #{name}", nil, nil,
        automatic_message_key: key,
        recipient_variables: {
          child.parent1_id => {
            'LIEN_CHOIX_THEME' => a_string_including("/s/#{children_support_module.id}", "sc=#{child.parent1.security_code}"),
            'PRENOM_ENFANT' => 'Hugo'
          }
        }
      ).and_call_original

      service = described_class.new(children_support_module, reminder_date, second_reminder).call

      expect(service.errors).to be_empty
    end

    it "n'envoie rien et signale le trio « #{name} » introuvable" do
      expect(ProgramAutomaticMessageService).not_to receive(:new)

      service = described_class.new(children_support_module, reminder_date, second_reminder).call

      expect(service.errors).to eq(["Trio introuvable : « #{name} » (clé #{key}), message non envoyé"])
    end
  end
end
