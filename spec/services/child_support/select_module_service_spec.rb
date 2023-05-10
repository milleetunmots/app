require 'rails_helper'

RSpec.describe ChildSupport::SelectModuleService do
  let(:child) { FactoryBot.create(:child, should_contact_parent1: true) }
  let(:support_module_list) { FactoryBot.create_list(:support_module, 3) }
  let(:child_support) do
    FactoryBot.create(
      :child_support,
      current_child: child,
      parent1_available_support_module_list: support_module_list.map(&:id)
    )
  end
  let(:planned_date) { Time.zone.today }
  let(:planned_hour) { Time.zone.now.strftime('%H:%M') }

  subject { ChildSupport::SelectModuleService.new(child, planned_date, planned_hour).call }

  context 'when no parent should be contacted' do
    it 'gets an error message' do
      child.should_contact_parent1 = false
      expect(subject.errors).to include 'Aucun des parents ne veut être contacté'
    end
  end

  context "when child support's available support module list is empty" do
    it "selection messages aren't sent to parents" do
      child_support.update!(parent1_available_support_module_list: [])
      subject
      expect_any_instance_of(SpotHit::SendSmsService).not_to receive(:call)
    end
  end

  context "when there aren't children support module not programmed for the child and their parent" do
    before { expect_any_instance_of(ProgramMessageService).to receive(:call) }
    it "it's created" do
      child_support
      expect { subject }.to change { ChildrenSupportModule.count }.by(1)
    end
  end

  context 'when there are only one available support module for the child and their parent' do
    it "it's choosen" do
      child_support.update!(parent1_available_support_module_list: [support_module_list.first.id])
      expect { subject }.to change { ChildrenSupportModule.count }.by(1)
      expect(ChildrenSupportModule.find_by(child_id: child.id, parent_id: child.parent1_id).support_module_id).to eq support_module_list.first.id
    end
  end

  context 'when selection messages are sent to parents' do
    it 'CheckToSendReminderJob is programmed' do
      # subject
      # expect_any_instance_of(SpotHit::SendSmsService).not_to receive(:call)
    end
  end
end
