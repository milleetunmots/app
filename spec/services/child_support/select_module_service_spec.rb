require 'rails_helper'

RSpec.describe ChildSupport::SelectModuleService do
  let(:child) { FactoryBot.create(:child, should_contact_parent1: true) }
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
      # pending ''
    end
  end

  context "when there aren't children support module not programmed for the child and their parent" do
    it "it's created" do
      # pending ''
    end
  end

  context 'when there are only one available support module for the child and their parent' do
    it "it's choosen" do
      # pending ''
    end
  end

  context 'when selection messages are sent to parents' do
    it 'CheckToSendReminderJob is programmed' do
      # pending ''
    end
  end
end
