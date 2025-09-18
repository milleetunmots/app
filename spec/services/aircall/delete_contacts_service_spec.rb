require 'rails_helper'

RSpec.describe Aircall::DeleteContactService do

  subject { Aircall::DeleteContactService.new }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('AIRCALL_ENABLED').and_return(true)
  end

  describe '#initialize' do
    it 'initializes errors as an empty array' do
      expect(subject.errors).to eq([])
    end

    it 'initializes deleted_contact_ids as an empty array' do
      expect(subject.deleted_contact_ids).to eq([])
    end
  end

  context 'when AIRCALL_ENABLED is not true' do
    before do
      allow(ENV).to receive(:[]).with('AIRCALL_ENABLED').and_return(nil)
    end

    it 'returns self without processing' do
      expect(subject.call).to eq(subject)
      expect(subject.deleted_contact_ids).to be_empty
      expect(subject.errors).to be_empty
      subject.call
    end
  end

  context 'when deleting a single contact' do
    let(:contact_id) { '123456' }
    let(:service) { Aircall::DeleteContactService.new(contact_id: contact_id) }

    before do
      status_stub = instance_double('HTTP::Response::Status', no_content?: true)
      response_stub = instance_double('HTTP::Response', status: status_stub)
      http_client_stub = instance_double('HTTP::Client')
      expected_url     = "#{Aircall::ApiBase::BASE_URL}" \
        "#{Aircall::ApiBase::CONTACTS_ENDPOINT}/#{contact_id}"
      allow(http_client_stub).to receive(:delete)
                                   .with(expected_url)
                                   .and_return(response_stub)
      allow(service).to receive(:http_client_with_auth).and_return(http_client_stub)
      allow(service).to receive(:sleep)
    end

    it 'successfully deletes the contact' do
      service.call

      expect(service.deleted_contact_ids).to eq([contact_id])
      expect(service.errors).to be_empty
    end
  end
end
