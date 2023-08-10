require 'rails_helper'

RSpec.describe ChildSupport::ProgramChosenModulesService do

  let(:group) { FactoryBot.create(:group) }
  let(:children) { FactoryBot.create_list(:child, 4, group: group, group_status: 'active' )}
  let(:child_without_group) { FactoryBot.create(:child) }
  let(:support_modules) { FactoryBot.create_list(:support_module, 2) }
  let(:children_support_modules) { [] }

  before do
    children.each do |child|
      children_support_modules << FactoryBot.create(:children_support_module,
                                                    child: child,
                                                    parent: child.parent1,
                                                    support_module: support_modules.sample)
    end
    children_support_modules << FactoryBot.create(:children_support_module,
                                                  child: child_without_group,
                                                  parent: child_without_group.parent1,
                                                  support_module: support_modules.sample)
    # allow_any_instance_of(SupportModule::ProgramService).to receive(:call).and_return(SupportModule::ProgramService.new(
    #   [],
    #   Time.zone.today.beginning_of_week(:monday) + 7.days,
    #   recipients: [],
    #   first_support_module: false
    # ))
  end

  subject { ChildSupport::ProgramChosenModulesService.new(children_support_modules.map(&:id), Time.zone.today.beginning_of_week(:monday) + 7.days).call }

  context 'when a child has no group' do
    # (ChildrenSupportModule::CheckCreditsService).to receive(:call).and_return(ChildrenSupportModule::CheckCreditsService.new([]))

    it 'gets an error message' do
      expect(subject.errors).to include 'Cohorte introuvable'
      # expect_any_instance_of(ProgramMessageService).not_to receive(:call)
    end
  end

end
