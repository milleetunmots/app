require 'rails_helper'

RSpec.describe ChildSupport::ChildrenDisengagementService do
  # let(:supporter) { FactoryBot.create(:admin_user, user_role: 'caller', name: 'Marie')}
  # let!(:group) { FactoryBot.create(:group) }
  # let!(:child_to_conserve) { FactoryBot.create(:child, group: group, group_status: 'active') }
  # let!(:disengaged_child) { FactoryBot.create(:child, group: group, group_status: 'active', first_name: 'Lucas') }
  # let!(:first_disengaged_child_in_siblings) { FactoryBot.create(:child, group: group, group_status: 'active') }
  # let!(:second_disengaged_child_in_siblings) { FactoryBot.create(:child, parent1: first_disengaged_child_in_siblings.parent1, group: group, group_status: 'active', birthdate: first_disengaged_child_in_siblings.birthdate + 2.days) }

  # context "when child support's are tagged 'desengage-2appelsKO'" do
  #   before(:each) do
  #     child_to_conserve.child_support.supporter_id = supporter.id
  #     child_to_conserve.child_support.save
  #
  #     disengaged_child.child_support.supporter_id = supporter.id
  #     disengaged_child.tag_list += ['desengage-2appelsKO']
  #     disengaged_child.child_support.save
  #     disengaged_child.save
  #
  #     first_disengaged_child_in_siblings.child_support.supporter_id = supporter.id
  #     first_disengaged_child_in_siblings.tag_list += ['desengage-2appelsKO']
  #     first_disengaged_child_in_siblings.child_support.save
  #     first_disengaged_child_in_siblings.save
  #   end
  #
  #   it "updates the children's group_status to 'disengaged'" do
  #     allow_any_instance_of(ProgramMessageService).to receive(:call).and_return(ProgramMessageService.new("01/01/2020", "12:30", [], ''))
  #
  #     ChildSupport::ChildrenDisengagementService.new(group.id).call
  #     expect(child_to_conserve.reload.group_status).to eq 'active'
  #     expect(disengaged_child.reload.group_status).to eq 'disengaged'
  #     expect(first_disengaged_child_in_siblings.reload.group_status).to eq 'disengaged'
  #     expect(second_disengaged_child_in_siblings.reload.group_status).to eq 'disengaged'
  #   end
  # end
end
