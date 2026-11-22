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
      expect(child_support.reload.stop_support_date.to_date).to eq Time.zone.today
    end

    it "the details to child_support's stop_support_details" do
      expect(child_support.reload.stop_support_details).to eq details
    end

    it "the children's support are stopped" do
      expect(child.reload.group_status).to eq 'stopped'
      expect(child.reload.group_end).to eq Time.zone.today
    end
  end

  # Entre minuit et 1h à Paris, un serveur en UTC est encore la veille.
  # travel_to sur un instant UTC fige aussi DateTime.now et Time.now en UTC, comme sur un tel serveur.
  context "quand l'accompagnement est arrêté à 00h30, heure de Paris, sur un serveur en UTC" do
    subject do
      travel_to(Time.utc(2027, 1, 11, 23, 30)) do
        ChildSupport::CallerStopSupportService.new(supporter.id, child_support.id, 'program', details).call
      end
    end

    it "date l'arrêt du jour de Paris" do
      subject

      expect(child_support.reload.stop_support_date.to_date).to eq Date.new(2027, 1, 12)
      expect(child_support.important_information).to include('Accompagnement arrêté le 12/01/2027')
      expect(child.reload.group_end).to eq Date.new(2027, 1, 12)
    end

    it "programme le SMS d'arrêt à l'heure de Paris" do
      expect(ProgramMessageService).to receive(:new).with('2027-01-12', '00:30', any_args).at_least(:once).and_call_original

      subject
    end
  end
end
