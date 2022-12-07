require 'rails_helper'

RSpec.describe Child::ExportBooksV1Service do
  describe "find_children_lists" do
    let_it_be(:first_group, reload: true) { FactoryBot.create(:group)}
    let_it_be(:second_group, reload: true) { FactoryBot.create(:group)}
    let_it_be(:third_group, reload: true) { FactoryBot.create(:group)}

    let_it_be(:first_group_between_0_and_12_children, reload: true) { FactoryBot.create_list(:child, 3, birthdate: Date.today.prev_month(5), group: first_group, group_status: 'active')}
    let_it_be(:second_group_between_0_and_12_children, reload: true) { FactoryBot.create_list(:child, 4, birthdate: Date.today.prev_month(5), group: second_group, group_status: 'active')}
    let_it_be(:third_group_between_0_and_12_children, reload: true) { FactoryBot.create_list(:child, 2, birthdate: Date.today.prev_month(3), group: third_group, group_status: 'active')}
    let_it_be(:no_group_between_0_and_12_children, reload: true) { FactoryBot.create_list(:child, 2, birthdate: Date.today.prev_month(4))}
    let_it_be(:second_group_between_12_and_24_children, reload: true) { FactoryBot.create_list(:child, 4, birthdate: Date.today.prev_month(15), group: second_group, group_status: 'active')}
    let_it_be(:third_group_between_12_and_24_children, reload: true) { FactoryBot.create_list(:child, 2, birthdate: Date.today.prev_month(13), group: third_group, group_status: 'active')}
    let_it_be(:third_group_more_than_24_children, reload: true) { FactoryBot.create_list(:child, 2, birthdate: Date.today.prev_month(25), group: third_group, group_status: 'active')}

    it "sorts children by age and group" do
      children_list_sorted_by_age_and_group = Child::ExportBooksV1Service.new.find_children_lists
      expect(children_list_sorted_by_age_and_group).to eq(
                                                         {
                                                           :months_between_0_and_12 => {
                                                             first_group.name.to_sym => first_group_between_0_and_12_children,
                                                             second_group.name.to_sym => second_group_between_0_and_12_children,
                                                             third_group.name.to_sym => third_group_between_0_and_12_children
                                                           },
                                                           :months_between_12_and_24 => {
                                                             second_group.name.to_sym => second_group_between_12_and_24_children,
                                                             third_group.name.to_sym => third_group_between_12_and_24_children
                                                           },
                                                           :months_more_than_24 => {
                                                             third_group.name.to_sym => third_group_more_than_24_children
                                                           }
                                                         }
                                                       )
    end
  end

end
