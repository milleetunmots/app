require 'rails_helper'

RSpec.describe ChildSupport::SelectModuleService do
  let_it_be(:group, reload: true) { FactoryBot.create(:group)}
  let_it_be(:support_module_list, reload: true) { FactoryBot.create_list(:support_module, 3) }
  let_it_be(:child_support, reload: true) do
    FactoryBot.create(
      :child_support,
      current_child: nil,
      parent1_available_support_module_list: support_module_list.map(&:id)
    )
  end
  let_it_be(:child, reload: true) { FactoryBot.create(:child, child_support: child_support, should_contact_parent1: true, group: group, group_status: 'active') }
  let(:planned_date) { Time.zone.today }
  let(:planned_hour) { Time.zone.now.strftime('%H:%M') }

  subject { ChildSupport::SelectModuleService.new(child, planned_date, planned_hour, 1).call }

  before do
    FactoryBot.create(:media_text_messages_bundle, name: 'Invitation à choisir le prochain thème', body1: 'Choisissez : {LIEN_CHOIX_THEME}', body2: nil, body3: nil)
              .update_column(:key, 'invitation_choix_theme')
  end

  context 'when no parent should be contacted' do
    it 'gets an error message' do
      child.should_contact_parent1 = false
      expect(subject.errors).to include 'Aucun des parents ne veut être contacté'
      expect_any_instance_of(ProgramMessageService).not_to receive(:call)
    end
  end

  context "when child support's available support module list is empty" do
    it "selection messages aren't sent to parents" do
      child_support.update!(parent1_available_support_module_list: [])
      subject
      expect_any_instance_of(ProgramMessageService).not_to receive(:call)
    end
  end

  context "when there aren't children support module not programmed for the child and their parent" do
    before { expect_any_instance_of(ProgramMessageService).to receive(:call).and_return(ProgramMessageService.new("01/01/2020", "12:30", [], '')) }
    it 'creates ChldrenSupportModule' do
      expect { subject }.to change { ChildrenSupportModule.count }.by(1)
    end
  end

  context 'when there are only one available support module for the child and their parent' do
    it 'choose the support_module directly and does not send message' do
      child_support.update!(parent1_available_support_module_list: [support_module_list.first.id])
      expect { subject }.to change { ChildrenSupportModule.count }.by(1)
      expect(ChildrenSupportModule.find_by(child_id: child.id, parent_id: child.parent1_id).support_module_id).to eq support_module_list.first.id
      expect_any_instance_of(ProgramMessageService).not_to receive(:call)
    end
  end

  context "when there is already a ChildrenSupportModule" do
    before do
      FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: nil)
      expect_any_instance_of(ProgramMessageService).to receive(:call).and_return(ProgramMessageService.new("01/01/2020", "12:30", [], ''))
    end
    it 'does not create a new ChldrenSupportModule' do
      expect { subject }.to change { ChildrenSupportModule.count }.by(0)
    end
  end

  describe 'invitation lue dans son trio' do
    it "envoie au parent le texte du trio, avec le délai, son lien de choix et le prénom de l'enfant concerné" do
      expect(ProgramAutomaticMessageService).to receive(:new).with(
        planned_date, planned_hour, ["parent.#{child.parent1_id}"], 'Choisissez : {LIEN_CHOIX_THEME}', nil, nil,
        automatic_message_key: 'invitation_choix_theme',
        recipient_variables: {
          child.parent1_id => {
            'DELAI_CHOIX_THEME' => 'quelques jours',
            'LIEN_CHOIX_THEME' => a_string_including('/s/', "sc=#{child.parent1.security_code}"),
            'PRENOM_ENFANT' => child.first_name
          }
        }
      ).and_call_original

      expect(subject.errors).to be_empty
    end

    it 'crée le module à choisir sans envoyer de message et signale le trio introuvable' do
      Media::TextMessagesBundle.where(key: 'invitation_choix_theme').delete_all
      expect(ProgramAutomaticMessageService).not_to receive(:new)

      service = subject

      expect(ChildrenSupportModule.where(child: child, parent: child.parent1, is_programmed: false)).to exist
      expect(service.errors).to include('Trio introuvable : « Invitation à choisir le prochain thème » (clé invitation_choix_theme), message non envoyé')
    end
  end
end
