require 'rails_helper'

RSpec.describe ChildSupport::ChildrenDisengagementService do
  let(:supporter) { FactoryBot.create(:admin_user, user_role: 'caller')}
  let!(:group) { FactoryBot.create(:group) }
  let!(:child_to_conserve) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:disengaged_child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:child_to_conserve_child_support) { FactoryBot.create(:child_support, current_child: child_to_conserve, supporter: supporter) }
  let!(:disengaged_child_child_support) { FactoryBot.create(:child_support, current_child: disengaged_child, tag_list: ['desengage-2appelsKO'], supporter: supporter) }

  context "when child support's are tagged 'desengage-2appelsKO'" do
    it "updates the children's group_status to 'disengaged'" do
      ChildSupport::ChildrenDisengagementService.new(group.id).call
      expect(child_to_conserve.reload.group_status).to eq 'active'
      expect(disengaged_child.reload.group_status).to eq 'disengaged'
    end
  end
end
