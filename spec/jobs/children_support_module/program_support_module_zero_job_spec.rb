require 'rails_helper'

RSpec.describe ChildrenSupportModule::ProgramSupportModuleZeroJob, type: :job do
  before do
    stub_request(:post, 'https://api.aircall.io/v1/contacts')
      .to_return(status: 200, body: '{"contact": {"id": 123}}', headers: {})
  end

  def create_child_with_both_parents(created_at:)
    travel_to(created_at) do
      parent1 = FactoryBot.create(:parent, phone_number: '0755880000')
      parent2 = FactoryBot.create(:parent, phone_number: '0755880001')
      FactoryBot.create(:child, first_name: 'Tom', last_name: 'Bernard', birthdate: Date.new(2026, 9, 5), parent1: parent1, parent2: parent2)
    end
  end

  describe '#perform_now' do
    it 'programme le module zéro sans traiter les doublons' do
      child = create_child_with_both_parents(created_at: Time.zone.local(2027, 1, 10, 10))
      duplicate = create_child_with_both_parents(created_at: Time.zone.local(2027, 1, 15, 10))
      group = travel_to(Time.zone.local(2027, 2, 19, 10)) do
        FactoryBot.create(:group, started_at: Date.new(2027, 3, 1), supporters_assigned_at: Time.zone.now)
      end
      program_service = instance_double(ChildrenSupportModule::ProgramService, call: nil)
      allow(ChildrenSupportModule::ProgramService).to receive(:new).and_return(program_service)
      allow(ChildSupport::DetectMissingSupporterService).to receive(:new).and_call_original

      travel_to(Time.zone.local(2027, 3, 1, 12)) { described_class.perform_now(group.id, group.started_at) }

      expect(child.reload).not_to be_discarded
      expect(duplicate.reload).not_to be_discarded
      expect(child.child_support.reload).not_to be_discarded
      expect(duplicate.child_support.reload).not_to be_discarded
      expect(ChildSupport::DetectMissingSupporterService).to have_received(:new)
      expect(program_service).to have_received(:call)
        .with(group.id, group.started_at, SupportModule::MODULE_ZERO_AGE_RANGE_LIST, SupportModule::LANGUAGE_MODULE_ZERO)
    end
  end
end
