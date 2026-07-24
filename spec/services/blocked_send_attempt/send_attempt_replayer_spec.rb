require 'rails_helper'

RSpec.describe BlockedSendAttempt::SendAttemptReplayer do
  let(:attempt) do
    FactoryBot.create(
      :blocked_send_attempt,
      replay_params: {
        planned_date: '2026-07-22',
        planned_hour: '10:00',
        recipients: ['parent.42'],
        message: 'Cliquez ici : https://non-whitelisted.example.com/page',
        rcs_media_id: nil,
        redirection_target_id: nil,
        quit_message: false,
        workshop_id: nil,
        supporter: nil,
        group_status: ['active'],
        provider: 'spothit',
        aircall_number_id: nil
      }
    )
  end

  it 'reconstruit un ProgramMessageService à partir des replay_params et le rejoue' do
    fake_service = instance_double(ProgramMessageService, errors: [], call: nil)
    allow(fake_service).to receive(:call).and_return(fake_service)

    expect(ProgramMessageService).to(
      receive(:new).
      with(
        '2026-07-22',
        '10:00',
        ['parent.42'],
        'Cliquez ici : https://non-whitelisted.example.com/page',
        nil,
        nil,
        false,
        nil,
        nil,
        ['active'],
        'spothit',
        nil,
        blocked_send_attempt: attempt
      ).
      and_return(fake_service)
    )

    result = described_class.new(attempt).call

    expect(result).to eq(fake_service)
  end
end
