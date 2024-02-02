require 'rails_helper'

RSpec.describe ChildSupport::ChildrenDisengagementService do
  let!(:group) { FactoryBot.create(:group) }
  let!(:child_to_conserve) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:disengaged_child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:child_to_conserve_child_support) { FactoryBot.create(:child_support, current_child: child_to_conserve, tag_list: ['estimé-desengagé']) }
  let!(:disengaged_child_child_support) { FactoryBot.create(:child_support, current_child: disengaged_child, tag_list: ['estimé-desengagé']) }
  let!(:support_module) { FactoryBot.create(:support_module) }

  context "when child support's available support module list is empty" do
    it "selection messages aren't sent to parents" do
      child_to_conserve_child_support.module4_chosen_by_parents = support_module
      child_to_conserve_child_support.save

      ChildSupport::ChildrenDisengagementService.new(group).call
      expect(child_to_conserve_child_support.reload.tag_list).to match_array ['estimé-desengagé-conservé']
      expect(disengaged_child_child_support.reload.tag_list).to match_array ['desengagé']
    end
  end
end
