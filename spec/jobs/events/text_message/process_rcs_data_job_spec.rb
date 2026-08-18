require 'rails_helper'

RSpec.describe Events::TextMessage::ProcessRcsDataJob, type: :job do
  subject { described_class }

  describe '#perform_later' do
    it 'enqueues the job on the low priority queue' do
      ActiveJob::Base.queue_adapter = :test
      expect {
        subject.perform_later({})
      }.to have_enqueued_job(described_class).on_queue('low').exactly(:once)
    end
  end

  describe '#perform' do
    let(:parent) { FactoryBot.create(:parent, phone_number: '0668021234') }
    let!(:text_message) do
      FactoryBot.create(
        :text_message,
        related: parent,
        message_provider: 'spot_hit',
        spot_hit_rcs_id: '45878',
        spot_hit_status: initial_status
      )
    end

    def payload(status:, channel_id:)
      {
        'events' => [
          {
            'messageStatusChanged' => {
              'status' => status,
              'channelId' => channel_id,
              'userId' => parent.phone_number,
              'context' => { 'campaign_id' => '45878' }
            }
          }
        ]
      }
    end

    context 'when a retrograde status arrives on the rcs channel' do
      let(:initial_status) { 1 } # Livré

      it 'reports to Rollbar and keeps the current status' do
        expect(Rollbar).to receive(:error).with('spot_hit_rcs_data: retrograde rcs status', anything)
        subject.perform_now(payload(status: 'SENT', channel_id: 'rcs'))
        expect(text_message.reload.spot_hit_status).to eq(1)
      end
    end

    context 'when the fallback sms fails after the rcs was sent' do
      let(:initial_status) { 2 } # Envoyé

      it 'applies the failed status and flags the message as fallback' do
        expect(Rollbar).not_to receive(:error)
        subject.perform_now(payload(status: 'DELIVERY_FAILED', channel_id: 'fallback'))
        text_message.reload
        expect(text_message.spot_hit_status).to eq(4)
        expect(text_message.is_fallback).to be(true)
      end
    end

    context 'when a retrograde status arrives on the fallback channel and the message is not failed' do
      let(:initial_status) { 1 } # Livré

      it 'reports to Rollbar and keeps the current status' do
        expect(Rollbar).to receive(:error).with('spot_hit_rcs_data: retrograde rcs status', anything)
        subject.perform_now(payload(status: 'SENT', channel_id: 'fallback'))
        expect(text_message.reload.spot_hit_status).to eq(1)
      end
    end

    context 'when the rcs failed and the fallback sms is then sent' do
      let(:initial_status) { 4 } # Échec

      it 'applies the sent status' do
        expect(Rollbar).not_to receive(:error)
        subject.perform_now(payload(status: 'SENT', channel_id: 'fallback'))
        text_message.reload
        expect(text_message.spot_hit_status).to eq(2)
        expect(text_message.is_fallback).to be(true)
      end
    end

    context 'when two parents share the phone number targeted by the campaign' do
      let(:initial_status) { 0 } # En attente
      let!(:sibling_parent) { FactoryBot.create(:parent, phone_number: parent.phone_number, first_name: 'Nouveau') }
      let!(:sibling_text_message) do
        FactoryBot.create(
          :text_message,
          related: sibling_parent,
          message_provider: 'spot_hit',
          spot_hit_rcs_id: '45878',
          spot_hit_status: 0
        )
      end

      it 'applies the status to every event of the campaign for that number' do
        expect(Rollbar).not_to receive(:error)
        subject.perform_now(payload(status: 'DELIVERED', channel_id: 'rcs'))
        expect(text_message.reload.spot_hit_status).to eq(1)
        expect(sibling_text_message.reload.spot_hit_status).to eq(1)
      end
    end

    context 'when one of the two parents sharing the number has been discarded' do
      let(:initial_status) { 0 } # En attente
      let!(:discarded_parent) { FactoryBot.create(:parent, phone_number: parent.phone_number, first_name: 'Supprime') }
      let!(:discarded_parent_text_message) do
        FactoryBot.create(
          :text_message,
          related: discarded_parent,
          message_provider: 'spot_hit',
          spot_hit_rcs_id: '45878',
          spot_hit_status: 0
        )
      end

      before { discarded_parent.discard }

      it 'still updates the event of the discarded parent' do
        expect(Rollbar).not_to receive(:error)
        subject.perform_now(payload(status: 'DELIVERED', channel_id: 'rcs'))
        expect(text_message.reload.spot_hit_status).to eq(1)
        expect(discarded_parent_text_message.reload.spot_hit_status).to eq(1)
      end
    end

    context 'when the only parent found for the number has been discarded' do
      let(:initial_status) { 0 } # En attente

      before { parent.discard }

      it 'still updates the event' do
        expect(Rollbar).not_to receive(:error)
        subject.perform_now(payload(status: 'DELIVERED', channel_id: 'rcs'))
        expect(text_message.reload.spot_hit_status).to eq(1)
      end
    end

    context 'when a message is received from a number shared by a discarded and a kept parent' do
      let(:initial_status) { 1 } # Livré
      let!(:kept_parent) { FactoryBot.create(:parent, phone_number: parent.phone_number, first_name: 'Actif') }
      let!(:kept_parent_text_message) do
        FactoryBot.create(
          :text_message,
          related: kept_parent,
          message_provider: 'spot_hit',
          spot_hit_rcs_id: '45878',
          spot_hit_status: 1
        )
      end

      before { parent.discard }

      def received_payload
        {
          'events' => [
            {
              'on' => Time.zone.now.iso8601,
              'userMessageReceived' => {
                'userId' => kept_parent.phone_number,
                'context' => { 'campaign_id' => '45878' },
                'content' => { 'text' => 'Merci !' }
              }
            }
          ]
        }
      end

      it 'attaches the received message to the parent still active' do
        expect(Rollbar).not_to receive(:error)
        expect { subject.perform_now(received_payload) }.to change(Events::TextMessage, :count).by(1)
        expect(Events::TextMessage.order(:id).last.related).to eq(kept_parent)
      end
    end
  end

  describe '#perform parent resolution' do
    let(:phone_number) { '0668021234' }

    def status_payload(user_id:, status: 'DELIVERED')
      {
        'events' => [
          {
            'messageStatusChanged' => {
              'status' => status,
              'channelId' => 'rcs',
              'userId' => user_id,
              'context' => { 'campaign_id' => '45878' }
            }
          }
        ]
      }
    end

    def received_payload(user_id:)
      {
        'events' => [
          {
            'on' => '2026-08-14T10:00:00+02:00',
            'userMessageReceived' => {
              'userId' => user_id,
              'context' => { 'campaign_id' => '45878' },
              'content' => { 'text' => 'Merci beaucoup !' }
            }
          }
        ]
      }
    end

    context 'when two parents share the same phone number' do
      let!(:other_parent) { FactoryBot.create(:parent, phone_number: phone_number) }
      let!(:recipient) { FactoryBot.create(:parent, phone_number: phone_number) }
      let!(:text_message) do
        FactoryBot.create(
          :text_message,
          related: recipient,
          message_provider: 'spot_hit',
          spot_hit_rcs_id: '45878',
          spot_hit_status: 2 # Envoyé
        )
      end

      it 'applies the status to the message of the parent who received the campaign' do
        expect(Rollbar).not_to receive(:error)
        subject.perform_now(status_payload(user_id: recipient.phone_number))
        expect(text_message.reload.spot_hit_status).to eq(1)
      end

      it 'attaches an incoming message to the parent who received the campaign' do
        expect(Rollbar).not_to receive(:error)
        expect {
          subject.perform_now(received_payload(user_id: recipient.phone_number))
        }.to change { Events::TextMessage.where(originated_by_app: false).count }.by(1)

        received = Events::TextMessage.where(originated_by_app: false).last
        expect(received.related).to eq(recipient)
        expect(received.related).not_to eq(other_parent)
      end
    end

    context 'when a discarded parent shares the phone number of an active parent' do
      let!(:discarded_parent) { FactoryBot.create(:parent, phone_number: phone_number, discarded_at: Time.zone.now) }
      let!(:active_parent) { FactoryBot.create(:parent, phone_number: phone_number) }

      it 'attaches an incoming message to the active parent' do
        expect(Rollbar).not_to receive(:error)
        subject.perform_now(received_payload(user_id: active_parent.phone_number))

        received = Events::TextMessage.where(originated_by_app: false).last
        expect(received.related).to eq(active_parent)
      end
    end

    context 'when the userId cannot be parsed' do
      it 'reports to Rollbar and creates nothing' do
        expect(Rollbar).to receive(:error).with('spot_hit_rcs_data: unparsable userId', anything)
        expect {
          subject.perform_now(received_payload(user_id: ''))
        }.not_to change(Events::TextMessage, :count)
      end
    end
  end
end
