require 'rails_helper'

RSpec.describe ChildSupport::ChildrenDisengagementService do
  let(:supporter) { FactoryBot.create(:admin_user, user_role: 'caller', name: 'Marie')}
  let!(:group) { FactoryBot.create(:group, type_of_support: 'with_calls') }

  let!(:child_to_conserve) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:child_support_to_conserve) { child_to_conserve.child_support.tap { |cs| cs.update!(supporter: supporter, call0_status: 'OK', call1_status: 'KO') } }

  let!(:disengaged_child) { FactoryBot.create(:child, group: group, group_status: 'active', first_name: 'Lucas') }
  let!(:disengaged_child_support) { disengaged_child.child_support.tap { |cs| cs.update!(supporter: supporter, call0_status: 'KO', call1_status: 'KO') } }


  let!(:first_disengaged_child_in_siblings) { FactoryBot.create(:child, group: group, group_status: 'active', birthdate: 1.year.ago) }
  let!(:second_disengaged_child_in_siblings) { FactoryBot.create(:child, parent1: first_disengaged_child_in_siblings.parent1, group: group, group_status: 'active', birthdate: first_disengaged_child_in_siblings.birthdate + 2.days) }
  let!(:siblings_child_support) { first_disengaged_child_in_siblings.child_support.tap { |cs| cs.update!(supporter: supporter, call0_status: 'Ne pas appeler', call1_status: 'KO') } }

  before(:each) do
    allow_any_instance_of(ProgramMessageService).to receive(:call).and_return(double(errors: []))
  end

  describe '#call' do
    let(:call_index) { 1 }
    subject { ChildSupport::ChildrenDisengagementService.new(group.id, call_index).call }

    context 'when processing call 1' do
      it 'disengages children with consecutive KO statuses' do
        expect { subject }.to change { disengaged_child.reload.group_status }.from('active').to('disengaged')
      end

      it 'disengages all siblings in the group' do
        subject
        expect(first_disengaged_child_in_siblings.reload.group_status).to eq 'disengaged'
        expect(second_disengaged_child_in_siblings.reload.group_status).to eq 'disengaged'
      end

      it 'does not disengage children with successful calls' do
        subject
        expect(child_to_conserve.reload.group_status).to eq 'active'
      end

      it "adds the 'desengage-2appelsKO' tag to the child support record" do
        subject
        expect(siblings_child_support.reload.tag_list).to include('desengage-2appelsKO')
      end
    end

    context 'when disengagement is manually avoided' do
      before do
        disengaged_child_support.update!(call1_avoid_disengagement_date: Time.zone.today)
      end

      it 'does not disengage the child even if statuses are KO' do
        subject
        expect(disengaged_child.reload.group_status).to eq 'active'
      end
    end

    context 'when a family has multiple active children' do
      it "uses the plural version of the message ('vos enfants')" do
        expect(ProgramMessageService).to receive(:new).with(
          Date.today,
          '13:00',
          %W[parent.#{disengaged_child.parent1_id} parent.#{first_disengaged_child_in_siblings.parent1_id}],
          "Bonjour,\n{PRENOM_ACCOMPAGNANTE} a essayé de vous appeler plusieurs fois mais n'a pas réussi à discuter avec vous. Avec 1001mots, quand on n'arrive pas à échanger, l'accompagnement se termine pour que d'autres familles en profitent. Les livres et SMS vont donc s'arrêter bientôt.\nMerci d'avoir participé à ce programme. On vous souhaite de beaux moments avec {PRENOM_ENFANT} !\nEt si vous avez encore 1 minute, dites-nous ici ce que vous avez pensé de 1001mots : https://form.typeform.com/to/fysdS3Sd#st=xxxxx\nL'équipe 1001mots",
          nil, nil, false, nil, nil, ['disengaged']
        ).and_call_original

        subject
      end
    end

    context 'when the group does not have calls' do
      it 'does nothing' do
        group.update(type_of_support: 'without_calls')
        service = ChildSupport::ChildrenDisengagementService.new(group.id, 1)
        expect(ProgramMessageService).not_to receive(:new)
        expect(disengaged_child.reload.group_status).to eq 'active'
        service.call
      end
    end
  end
end
