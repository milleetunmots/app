require 'rails_helper'

RSpec.describe SupportModule::ProgramService do
  let(:support_module) { FactoryBot.create(:support_module) }
  let(:recipients) { FactoryBot.create_list(:parent, 3) }
  let(:start_date) { Date.today.next_occurring(:monday) }
  let(:first_support_module) { false }

  let(:program_message_service) { instance_double(ProgramMessageService, call: double(errors: [])) }

  let(:service) do
    SupportModule::ProgramService.new(
      support_module,
      start_date,
      recipients: recipients,
      first_support_module: first_support_module
    )
  end

  before do
    allow(ProgramMessageService).to receive(:new).and_return(program_message_service)
    allow(Media::Image).to receive(:find_by).and_return(nil)
    allow(RedirectionTarget).to receive(:find_or_create_by).and_return(nil)
  end

  describe '#call' do
    context "when the start date is not a Monday" do
      let(:start_date) { Date.today.next_occurring(:tuesday) }

      it "returns an error" do
        result = service.call
        expect(result.errors).to include('La date de démarrage doit être un lundi')
      end

      it 'does not schedule any message' do
        expect(ProgramMessageService).not_to receive(:new)
        service.call
      end
    end

    context 'when the start date is a Monday' do
      let(:medium1) { FactoryBot.create(:medium, body1: 'Message 1.1', body2: 'Message 1.2', body3: 'Message 1.3') }
      let(:additional_medium) { FactoryBot.create(:medium, body1: 'Message additionnel') }
      let(:week1) { FactoryBot.create(:support_module_week, medium: medium1, additional_medium: additional_medium) }

      let(:medium2) { FactoryBot.create(:medium, body1: 'Message 2.1', body2: 'Message 2.2', body3: 'Message 2.3') }
      let(:week2) { FactoryBot.create(:support_module_week, medium: medium2) }

      before do
        allow(support_module).to receive(:support_module_weeks).and_return([week1, week2])
      end

      it 'schedule the messages according to the days and times' do
        expect(ProgramMessageService).to receive(:new).with(start_date + 1.day, '12:30', recipients, 'Message 1.1', nil, nil).and_return(program_message_service)
        expect(ProgramMessageService).to receive(:new).with(start_date + 3.days, '12:30', recipients, 'Message 1.2', nil, nil).and_return(program_message_service)
        expect(ProgramMessageService).to receive(:new).with(start_date + 4.days, '12:30', recipients, 'Message 1.3', nil, nil).and_return(program_message_service)
        expect(ProgramMessageService).to receive(:new).with(start_date + 5.days, '14:00', recipients, 'Message additionnel', nil, nil).and_return(program_message_service)

        expect(ProgramMessageService).to receive(:new).with(start_date + 1.week + 1.day, '12:30', recipients, 'Message 2.1', nil, nil).and_return(program_message_service)
        expect(ProgramMessageService).to receive(:new).with(start_date + 1.week + 3.day, '12:30', recipients, 'Message 2.2', nil, nil).and_return(program_message_service)
        expect(ProgramMessageService).to receive(:new).with(start_date + 1.week + 5.day, '14:00', recipients, 'Message 2.3', nil, nil).and_return(program_message_service)

        service.call
      end

      context 'when first_support_module is true' do
        let(:first_support_module) { true }

        it 'schedule the first message on that Monday' do
          allow(support_module).to receive(:support_module_weeks).and_return([week1])

          expect(ProgramMessageService).to receive(:new).with(start_date, '12:30', recipients, 'Message 1.1', nil, nil).and_return(program_message_service)
          expect(ProgramMessageService).to receive(:new).with(start_date + 3.days, '12:30', recipients, 'Message 1.2', nil, nil).and_return(program_message_service)

          service.call
        end
      end
    end
  end
end
