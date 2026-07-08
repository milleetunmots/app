require 'rails_helper'

RSpec.describe Events::TextMessage::RemoveUnprogrammedJob, type: :job do
  subject(:job) { described_class.new }

  let(:api_url) { 'https://www.spot-hit.fr/api/campaign/list' }

  before { allow(job).to receive(:sleep) }

  def campaign_list(status, product = 'sms')
    [['245174', 'test', '', '1', '1681370520', status.to_s, '', product, '1681284185', '+33600000000']]
  end

  describe '#perform' do
    context 'when the SMS campaign no longer exists on SpotHit' do
      let!(:text_message) { FactoryBot.create(:text_message, spot_hit_status: 0, spot_hit_message_id: '245174') }

      it 'destroys the message' do
        stub_request(:get, api_url)
          .with(query: hash_including('id' => '245174', 'product' => 'sms'))
          .to_return(body: '[]')

        expect { job.perform }.to change(Events::TextMessage, :count).by(-1)
      end
    end

    context 'when the SMS campaign exists' do
      let!(:text_message) { FactoryBot.create(:text_message, spot_hit_status: 0, spot_hit_message_id: '245174') }

      it 'updates the status from the campaign status' do
        stub_request(:get, api_url)
          .with(query: hash_including('id' => '245174', 'product' => 'sms'))
          .to_return(body: campaign_list(2).to_json)

        job.perform

        expect(text_message.reload.spot_hit_status).to eq(2)
      end

      it 'keeps the message pending when the campaign status is unknown' do
        stub_request(:get, api_url)
          .with(query: hash_including('id' => '245174'))
          .to_return(body: campaign_list(9).to_json)

        job.perform

        expect(text_message.reload.spot_hit_status).to eq(0)
      end
    end

    context 'when several messages belong to the same campaign' do
      let!(:first_message) { FactoryBot.create(:text_message, spot_hit_status: 0, spot_hit_message_id: '245174') }
      let!(:second_message) { FactoryBot.create(:text_message, spot_hit_status: 0, spot_hit_message_id: '245174') }

      it 'calls the API once and updates every message of the campaign' do
        stub = stub_request(:get, api_url)
               .with(query: hash_including('id' => '245174', 'product' => 'sms'))
               .to_return(body: campaign_list(2).to_json)

        job.perform

        expect(stub).to have_been_requested.once
        expect(first_message.reload.spot_hit_status).to eq(2)
        expect(second_message.reload.spot_hit_status).to eq(2)
      end
    end

    context 'with an RCS message' do
      let!(:text_message) { FactoryBot.create(:text_message, spot_hit_status: 0, spot_hit_rcs_id: '999') }

      it 'checks the rcs product with the RCS id' do
        stub = stub_request(:get, api_url)
               .with(query: hash_including('id' => '999', 'product' => 'rcs'))
               .to_return(body: campaign_list(4, 'rcs').to_json)

        job.perform

        expect(stub).to have_been_requested
        expect(text_message.reload.spot_hit_status).to eq(4)
      end
    end

    context 'when the message has no SpotHit id' do
      let!(:text_message) { FactoryBot.create(:text_message, spot_hit_status: 0) }

      it 'leaves the message untouched without calling the API' do
        job.perform

        expect(text_message.reload.spot_hit_status).to eq(0)
        expect(a_request(:get, api_url)).not_to have_been_made
      end
    end

    context 'when the API returns an error' do
      let!(:text_message) { FactoryBot.create(:text_message, spot_hit_status: 0, spot_hit_message_id: '245174') }

      it 'keeps the message and moves on to the next one' do
        stub_request(:get, api_url)
          .with(query: hash_including('id' => '245174'))
          .to_return(body: { 'erreurs' => 'invalid key' }.to_json)

        expect { job.perform }.not_to change(Events::TextMessage, :count)
        expect(text_message.reload.spot_hit_status).to eq(0)
      end
    end
  end
end
