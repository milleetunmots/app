require 'rails_helper'

RSpec.describe ChildSupport::ChildrenDisengagementService do
  let!(:group) { FactoryBot.create(:group) }
  let!(:child_to_conserve) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:disengaged_child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:child_to_conserve_child_support) { FactoryBot.create(:child_support, current_child: child_to_conserve, tag_list: ['estime-desengage-t2']) }
  let!(:disengaged_child_child_support) { FactoryBot.create(:child_support, current_child: disengaged_child, tag_list: ['estime-desengage-t2']) }
  let!(:support_module) { FactoryBot.create(:support_module) }

  context "when child support's available support module list is empty" do
    it "selection messages aren't sent to parents" do
      child_to_conserve_child_support.module4_chosen_by_parents = support_module
      child_to_conserve_child_support.save

      ChildSupport::ChildrenDisengagementService.new(grou.id).call
      expect(child_to_conserve_child_support.reload.tag_list).to match_array ['estime-desengage-conserve-t2']
      expect(disengaged_child_child_support.reload.tag_list).to match_array ['desengage-t2']
    end
  end
end
