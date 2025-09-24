require 'rails_helper'

RSpec.describe Group::DistributeChildSupportsToSupportersService do
  let(:group) { FactoryBot.create(:group) }
  let(:first_supporter) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:second_supporter) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:third_supporter) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:count_by_supporter) do
    [
      { admin_user_id: first_supporter.id, child_supports_count: 5, age_range: '4-9', assigned_child_supports_count: 0 },
      { admin_user_id: second_supporter.id, child_supports_count: 3, age_range: '10-16', assigned_child_supports_count: 0 },
      { admin_user_id: third_supporter.id, child_supports_count: 4, age_range: nil, assigned_child_supports_count: 0 }
    ]
  end

  describe '#call' do
    subject { Group::DistributeChildSupportsToSupportersService.new(group, count_by_supporter).call }

    context 'when there are child supports to assign' do
      let!(:children_with_siblings) { FactoryBot.create_list(:child, 12, group: group, group_status: 'active') }

      it 'assigns all child supports to supporters' do
        subject
        expect(ChildSupport.in_group(group.id).without_supporter.count).to eq(0)
      end

      it 'respects supporter capacities' do
        subject
        count_by_supporter.each do |supporter|
          expect(ChildSupport.where(supporter_id: supporter[:admin_user_id]).count).to be <= supporter[:child_supports_count]
        end
      end
    end
  end
end
