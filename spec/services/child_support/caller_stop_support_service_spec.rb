require 'rails_helper'

RSpec.describe ChildSupport::CallerStopSupportService do
  let!(:group) { FactoryBot.create(:group) }
  let!(:child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:child_support) { child.child_support }
  let!(:supporter) { FactoryBot.create(:admin_user) }
  let!(:details) { Faker::Quote.famous_last_words }

  before(:each) do
    allow_any_instance_of(ProgramMessageService).to receive(:call).and_return(ProgramMessageService.new("01/01/2020", "12:30", [], ''))
  end

  context "when a caller stop support" do
    subject { ChildSupport::CallerStopSupportService.new(supporter.id, child_support.id, 'program', details).call }
    before(:each) do
      subject
    end

    it "the supporter's id is added to the child_support's stop_support_caller_id" do
      expect(child_support.reload.stop_support_caller_id).to be supporter.id
    end

    it "today's date is added to the child_support's stop_support_date" do
      expect(child_support.reload.stop_support_date.to_date).to eq DateTime.now.to_date
    end

    it "the details to child_support's stop_support_details" do
      expect(child_support.reload.stop_support_details).to eq details
    end

    it "the children's support are stopped" do
      expect(child.reload.group_status).to eq 'stopped'
      expect(child.reload.group_end).to eq DateTime.now.to_date
    end
  end
end
