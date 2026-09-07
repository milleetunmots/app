require 'rails_helper'

RSpec.describe 'Child message recipient filtering' do
  let(:parent1) { FactoryBot.create(:parent) }
  let(:parent2) { FactoryBot.create(:parent) }
  let(:group) { FactoryBot.create(:group) }
  let(:child) do
    FactoryBot.create(
      :child,
      parent1: parent1,
      parent2: parent2,
      group: group,
      group_status: 'active',
      should_contact_parent1: true,
      should_contact_parent2: false
    )
  end
  let(:sender) { instance_double(SpotHit::SendRcsService, errors: [], sent?: true) }
  let(:recipients) { ["child.#{child.id}"] }
  let(:planned_date) { Time.zone.today }
  let(:planned_hour) { '12:30' }

  before do
    allow(sender).to receive(:call).and_return(sender)
  end

  it 'only sends the quit message to parents kept by ProgramMessageService filters' do
    captured_recipients = nil
    allow(SpotHit::SendRcsService).to receive(:new) do |**arguments|
      captured_recipients = arguments[:recipients]
      sender
    end

    Child::ProgramQuitMessageService.new(
      planned_date,
      planned_hour,
      recipients,
      'Continuer : {QUIT_LINK}'
    ).call

    expect(captured_recipients.keys).to contain_exactly(parent1.id)
    expect(captured_recipients[parent1.id]).to include('QUIT_LINK')
  end

  it 'only sends the end-of-support message to parents kept by ProgramMessageService filters' do
    captured_recipients = nil
    allow(SpotHit::SendRcsService).to receive(:new) do |**arguments|
      captured_recipients = arguments[:recipients]
      sender
    end

    Child::StopSupportMessageService.new(
      planned_date,
      planned_hour,
      recipients,
      'Fin pour {PRENOM_ENFANT}'
    ).call

    expect(captured_recipients).to eq(parent1.id => { 'PRENOM_ENFANT' => child.first_name })
  end
end
