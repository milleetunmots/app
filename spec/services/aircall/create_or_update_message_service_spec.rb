require 'rails_helper'

RSpec.describe Aircall::CreateOrUpdateMessageService do
  let(:supporter) { FactoryBot.create(:admin_user, name: 'Séverine Martin', aircall_phone_number: '+33100000001') }
  let!(:other_admin) { FactoryBot.create(:admin_user, name: 'Aïnhoa Soler', email: 'ainhoa@example.com', aircall_phone_number: '+33100000002') }
  let(:parent) { FactoryBot.create(:parent) }
  let!(:child) { FactoryBot.create(:child, parent1: parent) }
  let(:child_support) { child.reload.child_support }
  let(:base_payload) { { 'id' => 'da03a5fc-67be', 'external_number' => parent.phone_number, 'body' => 'Bonjour' } }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('AIRCALL_ENABLED').and_return('true')
    child_support.update!(supporter: supporter)
  end

  def call(payload)
    described_class.new(payload: payload).call
  end

  it 'resolves the caller from the Aircall number when present' do
    service = call(base_payload.merge('status' => 'sent', 'number' => { 'digits' => '+33 1 00 00 00 02' }))

    expect(service.errors).to be_empty
    expect(service.message.caller).to eq(other_admin)
  end

  context 'when the payload has no Aircall number' do
    it 'resolves the caller from the Aircall user on message.sent' do
      service = call(base_payload.merge('user' => { 'id' => 1, 'name' => 'Ainhoa Soler', 'email' => 'other@gmail.com' }))

      expect(service.errors).to be_empty
      expect(service.message).to have_attributes(caller: other_admin, direction: 'outbound', status: 'sent', child_support_id: child_support.id)
    end

    it 'falls back to the supporter of the family on message.received' do
      service = call(base_payload.merge('status' => 'received'))

      expect(service.errors).to be_empty
      expect(service.message).to have_attributes(caller: supporter, direction: 'inbound')
    end

    it 'updates the status of an already saved message on message.status_updated' do
      call(base_payload.merge('user' => { 'email' => 'AINHOA@example.com' }))
      service = call({ 'id' => base_payload['id'], 'external_number' => parent.phone_number, 'status' => 'delivered' })

      expect(service.errors).to be_empty
      expect(AircallMessage.find_by(aircall_id: base_payload['id'])).to have_attributes(status: 'delivered', caller_id: other_admin.id, body: 'Bonjour')
    end

    it 'returns an error instead of raising when no caller can be found' do
      child_support.update!(supporter: nil)

      service = nil
      expect { service = call(base_payload.merge('status' => 'received')) }.not_to change(AircallMessage, :count)
      expect(service.errors).to contain_exactly(a_string_including('accompagnante introuvable'))
    end
  end
end
