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

    # Une réponse entrante porte le même spot_hit_rcs_id que la campagne : un
    # callback de statut ne doit jamais la réécrire, elle vient du parent.
    context 'when the parent replied to the campaign' do
      let(:initial_status) { 2 } # Envoyé
      let!(:received_message) do
        Events::TextMessage.create!(
          related: parent,
          body: 'Réponse du parent',
          spot_hit_rcs_id: '45878',
          spot_hit_status: 1,
          occurred_at: 1.hour.ago,
          originated_by_app: false
        )
      end

      it 'applies the status to the sent message only' do
        subject.perform_now(payload(status: 'READ', channel_id: 'rcs'))

        expect(text_message.reload.spot_hit_status).to eq(6)
        expect(received_message.reload.spot_hit_status).to eq(1)
      end
    end

    context 'when a retrograde status arrives on the rcs channel' do
      let(:initial_status) { 1 } # Livré

      # SpotHit ne garantit pas l'ordre des événements : c'est un cas normal.
      it 'garde le statut courant sans alerte Rollbar' do
        expect(Rollbar).not_to receive(:error)
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

      it 'garde le statut courant sans alerte Rollbar' do
        expect(Rollbar).not_to receive(:error)
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

  describe 'alertes Rollbar sur les campagnes' do
    let!(:ines) { FactoryBot.create(:parent, phone_number: '+33612345678') }
    let!(:marc) { FactoryBot.create(:parent, phone_number: '+33698765432') }
    let!(:ines_text_message) do
      FactoryBot.create(
        :text_message,
        related: ines,
        message_provider: 'spot_hit',
        spot_hit_rcs_id: '45878',
        spot_hit_status: 2 # Envoyé
      )
    end
    let(:unknown_phone_number) { '+33700000000' }

    def status_event(campaign_id:, user_id:, status: 'DELIVERED', channel_id: 'rcs', error_code: nil)
      content = {
        'status' => status,
        'channelId' => channel_id,
        'userId' => user_id,
        'context' => { 'campaign_id' => campaign_id }
      }
      content['error'] = { 'code' => error_code } if error_code
      { 'messageStatusChanged' => content }
    end

    def received_event(campaign_id:, user_id:, text: 'Bonjour')
      content_event(campaign_id: campaign_id, user_id: user_id, content: { 'text' => text })
    end

    def content_event(campaign_id:, user_id:, content:)
      {
        'on' => '2026-10-29T10:00:00Z',
        'userMessageReceived' => {
          'channelId' => 'rcs',
          'userId' => user_id,
          'context' => { 'campaign_id' => campaign_id },
          'content' => content
        }
      }
    end

    def payload(*events)
      { 'events' => events }
    end

    context "quand la campagne n'a pas été envoyée par l'app" do
      [
        ['READ', '+33612345678'],
        ['DELIVERED', '+33700000000'],
        ['DELIVERY_FAILED', '+33612345678']
      ].each do |status, phone_number|
        it "ignore le statut #{status} pour #{phone_number} sans alerte Rollbar" do
          expect(Rollbar).not_to receive(:error)
          subject.perform_now(payload(status_event(campaign_id: '82177', user_id: phone_number, status: status)))
          expect(ines_text_message.reload.spot_hit_status).to eq(2)
        end
      end

      it "crée la réponse texte d'un parent connu sans alerte Rollbar" do
        expect(Rollbar).not_to receive(:error)
        expect do
          subject.perform_now(payload(received_event(campaign_id: '82177', user_id: ines.phone_number)))
        end.to change { Events::TextMessage.where(related: ines, originated_by_app: false, body: 'Bonjour').count }.by(1)
      end

      it "ignore la réponse d'un numéro hors base sans alerte Rollbar" do
        expect(Rollbar).not_to receive(:error)
        expect do
          subject.perform_now(payload(received_event(campaign_id: '82177', user_id: unknown_phone_number)))
        end.not_to change(Events::TextMessage, :count)
      end

      it 'ignore le statut même si une réponse entrante porte déjà la campagne' do
        Events::TextMessage.create!(
          related: ines,
          body: 'Réponse précédente',
          spot_hit_rcs_id: '82177',
          spot_hit_status: 1,
          occurred_at: 1.day.ago,
          originated_by_app: false
        )

        expect(Rollbar).not_to receive(:error)
        subject.perform_now(payload(status_event(campaign_id: '82177', user_id: ines.phone_number, status: 'READ')))
      end
    end

    context "quand la campagne a été envoyée par l'app" do
      it "lève une seule alerte si aucun event n'existe pour ce parent" do
        expect(Rollbar).to receive(:error)
          .with('spot_hit_rcs_data: text_message not found for known campaign', hash_including(:event_content))
          .once
        subject.perform_now(payload(status_event(campaign_id: '45878', user_id: marc.phone_number)))
      end

      it "lève une seule alerte « parent not found » pour un statut d'un numéro hors base" do
        expect(Rollbar).to receive(:error)
          .with('spot_hit_rcs_data: parent not found', hash_including(:event_content))
          .once
        subject.perform_now(payload(status_event(campaign_id: '45878', user_id: unknown_phone_number)))
      end

      [
        %w[fallback USER_UNAVAILABLE],
        %w[rcs USER_UKNOWN],
        %w[rcs USER_BLOCKED],
        %w[rcs CHANNEL_REJECTED],
        %w[rcs CHANNEL_UNAVAILABLE],
        %w[rcs CHANNEL_INTERNAL_ISSUE],
        %w[rcs CHANNEL_OTHER_ISSUE],
        %w[rcs CLIENT_MESSAGE_EXPIRED]
      ].each do |channel_id, error_code|
        it "enregistre l'échec #{error_code} sur le canal #{channel_id} sans alerte Rollbar" do
          expect(Rollbar).not_to receive(:error)
          subject.perform_now(
            payload(
              status_event(
                campaign_id: '45878',
                user_id: ines.phone_number,
                status: 'DELIVERY_FAILED',
                channel_id: channel_id,
                error_code: error_code
              )
            )
          )
          ines_text_message.reload
          expect(ines_text_message.spot_hit_status).to eq(4)
          expect(ines_text_message.rcs_error_code).to eq(error_code)
        end
      end

      # Depuis « Envoyé », DELIVERY_RETRIED (« En cours ») est rétrograde et ignoré :
      # on part d'un event encore en attente pour que l'essai s'applique.
      it "enregistre l'erreur d'un nouvel essai de livraison sans alerte Rollbar" do
        ines_text_message.update!(spot_hit_status: 0) # En attente
        expect(Rollbar).not_to receive(:error)
        subject.perform_now(
          payload(
            status_event(
              campaign_id: '45878',
              user_id: ines.phone_number,
              status: 'DELIVERY_RETRIED',
              error_code: 'CLIENT_QUOTA_EXCEEDED'
            )
          )
        )
        expect(ines_text_message.reload.rcs_error_code).to eq('CLIENT_QUOTA_EXCEEDED')
      end

      %w[
        CLIENT_MESSAGE_INVALID
        CLIENT_CONFIGURATION_INVALID
        CLIENT_QUOTA_EXCEEDED
        CLIENT_MESSAGE_FORBIDDEN
        INTERNAL_NOT_IMPLEMENTED
        INTERNAL_OTHER_ISSUE
      ].each do |error_code|
        it "enregistre l'échec #{error_code} et lève une alerte Rollbar" do
          expect(Rollbar).to receive(:error)
            .with('spot_hit_rcs_data: RCS delivery error', hash_including(:event_content))
            .once
          subject.perform_now(
            payload(
              status_event(
                campaign_id: '45878',
                user_id: ines.phone_number,
                status: 'DELIVERY_FAILED',
                error_code: error_code
              )
            )
          )
          ines_text_message.reload
          expect(ines_text_message.spot_hit_status).to eq(4)
          expect(ines_text_message.rcs_error_code).to eq(error_code)
        end
      end

      context "quand deux parents partagent le numéro et que l'erreur vient de 1001mots" do
        let!(:sami) { FactoryBot.create(:parent, phone_number: ines.phone_number, first_name: 'Sami') }
        let!(:sami_text_message) do
          FactoryBot.create(
            :text_message,
            related: sami,
            message_provider: 'spot_hit',
            spot_hit_rcs_id: '45878',
            spot_hit_status: 2 # Envoyé
          )
        end

        it 'met à jour les deux events et ne lève qu\'une seule alerte Rollbar' do
          expect(Rollbar).to receive(:error)
            .with('spot_hit_rcs_data: RCS delivery error', hash_including(:event_content))
            .once
          subject.perform_now(
            payload(
              status_event(
                campaign_id: '45878',
                user_id: ines.phone_number,
                status: 'DELIVERY_FAILED',
                error_code: 'CLIENT_QUOTA_EXCEEDED'
              )
            )
          )
          [ines_text_message, sami_text_message].each do |text_message|
            text_message.reload
            expect(text_message.spot_hit_status).to eq(4)
            expect(text_message.rcs_error_code).to eq('CLIENT_QUOTA_EXCEEDED')
          end
        end
      end

      it "lève une seule alerte « parent not found » pour une réponse d'un numéro hors base" do
        expect(Rollbar).to receive(:error)
          .with('spot_hit_rcs_data: parent not found', hash_including(:event_content))
          .once
        expect do
          subject.perform_now(payload(received_event(campaign_id: '45878', user_id: unknown_phone_number)))
        end.not_to change(Events::TextMessage, :count)
      end
    end

    context 'quand le parent répond autrement que par un message écrit' do
      {
        'postback' => { 'postback' => { 'buttonType' => 'openUrl', 'text' => 'Je vote pour 1001mots', 'payload' => 'c1_a1' } },
        'media' => { 'media' => { 'type' => 'image/png', 'source' => 'https://exemple.fr/photo.png' } },
        'location' => { 'location' => { 'latitude' => 48.82, 'longitude' => 2.23 } },
        'typing' => { 'typing' => {} },
        'optin' => { 'optin' => { 'text' => 'Get Started' } }
      }.each do |type, content|
        it "ignore le contenu #{type} sans alerte Rollbar" do
          expect(Rollbar).not_to receive(:error)
          expect do
            subject.perform_now(payload(content_event(campaign_id: '45878', user_id: ines.phone_number, content: content)))
          end.not_to change(Events::TextMessage, :count)
        end

        it "ignore le contenu #{type} hors campagne sans alerte Rollbar" do
          expect(Rollbar).not_to receive(:error)
          subject.perform_now(payload(content_event(campaign_id: nil, user_id: ines.phone_number, content: content)))
        end

        it "ignore le contenu #{type} d'un numéro hors base sans alerte Rollbar" do
          expect(Rollbar).not_to receive(:error)
          subject.perform_now(payload(content_event(campaign_id: '45878', user_id: unknown_phone_number, content: content)))
        end

        it "ignore le contenu #{type} sans date sans alerte Rollbar" do
          expect(Rollbar).not_to receive(:error)
          event = content_event(campaign_id: '45878', user_id: ines.phone_number, content: content).except('on')
          subject.perform_now(payload(event))
        end
      end

      it "alerte toujours sur une réponse écrite hors campagne" do
        expect(Rollbar).to receive(:error)
          .with('spot_hit_rcs_data: campaign_id not found', hash_including(:event_content))
          .once
        subject.perform_now(payload(received_event(campaign_id: nil, user_id: ines.phone_number)))
      end

      it 'enregistre une désinscription RCS STOP sans alerte Rollbar' do
        expect(Rollbar).not_to receive(:error)
        expect do
          subject.perform_now(
            payload(content_event(campaign_id: '45878', user_id: ines.phone_number, content: { 'optout' => { 'text' => 'STOP' } }))
          )
        end.to change { Events::TextMessage.where(related: ines, body: 'STOP').count }.by(1)
      end

      it "lève une alerte dédiée pour une désinscription RCS qui n'est pas un STOP" do
        expect(Rollbar).to receive(:error)
          .with('spot_hit_rcs_data: RCS opt-out non traité', hash_including(:event_content))
          .once
        expect do
          subject.perform_now(
            payload(content_event(campaign_id: '45878', user_id: ines.phone_number, content: { 'optout' => { 'text' => 'ARRET' } }))
          )
        end.not_to change(Events::TextMessage, :count)
      end

      it 'lève une alerte pour un type de contenu que l\'app ne connaît pas' do
        expect(Rollbar).to receive(:error)
          .with('spot_hit_rcs_data: message received unsupported content', hash_including(:event_content))
          .once
        expect do
          subject.perform_now(
            payload(content_event(campaign_id: '45878', user_id: ines.phone_number, content: { 'sticker' => { 'id' => '42' } }))
          )
        end.not_to change(Events::TextMessage, :count)
      end

      it 'crée la réaction emoji comme une réponse texte, sans alerte Rollbar' do
        expect(Rollbar).not_to receive(:error)
        expect do
          subject.perform_now(
            payload(
              content_event(campaign_id: '45878', user_id: ines.phone_number, content: { 'text' => '👍', 'isReaction' => true })
            )
          )
        end.to change { Events::TextMessage.where(related: ines, originated_by_app: false, body: '👍').count }.by(1)
      end
    end

    context 'quand un lot mêle bruit et anomalie' do
      it "traite chaque événement et ne lève que l'alerte de l'anomalie" do
        expect(Rollbar).to receive(:error)
          .with('spot_hit_rcs_data: parent not found', hash_including(:event_content))
          .once
        subject.perform_now(
          payload(
            status_event(campaign_id: '82177', user_id: ines.phone_number, status: 'READ'),
            content_event(
              campaign_id: '45878',
              user_id: ines.phone_number,
              content: { 'postback' => { 'buttonType' => 'openUrl', 'text' => 'Je vote pour 1001mots', 'payload' => 'c1_a1' } }
            ),
            status_event(campaign_id: '45878', user_id: unknown_phone_number),
            status_event(campaign_id: '45878', user_id: ines.phone_number)
          )
        )
        expect(ines_text_message.reload.spot_hit_status).to eq(1) # Livré
      end
    end
  end

  describe 'désinscription RCS' do
    def stop_payload(phone_number:, campaign_id: '45878', optout_text: 'STOP', on: '2026-11-18T09:00:00Z')
      event = {
        'userMessageReceived' => {
          'channelId' => 'rcs',
          'userId' => phone_number,
          'context' => { 'campaign_id' => campaign_id },
          'content' => { 'optout' => { 'text' => optout_text } }
        }
      }
      event['on'] = on if on
      { 'events' => [event] }
    end

    it "n'applique pas le STOP quand la désinscription ne contient pas le texte STOP" do
      parent = FactoryBot.create(:parent, phone_number: '+33612345678')
      child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'active')

      subject.perform_now(stop_payload(phone_number: '+33612345678', optout_text: 'ARRET'))

      expect(child.reload).to have_attributes(should_contact_parent1: true, group_status: 'active')
      expect(Events::TextMessage.where(related: parent, body: 'STOP')).to be_empty
    end

    it "décoche le parent seul, arrête l'enfant et historise le STOP" do
      travel_to Time.zone.local(2026, 11, 18, 10)
      parent = FactoryBot.create(:parent, phone_number: '+33612345678')
      child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'active')

      subject.perform_now(stop_payload(phone_number: '+33612345678'))

      expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'stopped', group_end: Date.new(2026, 11, 18))
      expect(Events::TextMessage.find_by(related: parent, body: 'STOP')).to have_attributes(
        spot_hit_rcs_id: '45878',
        occurred_at: Time.zone.parse('2026-11-18T09:00:00Z'),
        originated_by_app: false
      )
    end

    it "décoche le parent 2 sans arrêter l'enfant quand le parent 1 reste à contacter" do
      parent1 = FactoryBot.create(:parent, phone_number: '+33611111111')
      parent2 = FactoryBot.create(:parent, phone_number: '+33622222222')
      child = FactoryBot.create(
        :child,
        parent1: parent1, parent2: parent2, should_contact_parent2: true,
        group: FactoryBot.create(:group), group_status: 'active'
      )

      subject.perform_now(stop_payload(phone_number: '+33622222222'))

      expect(child.reload).to have_attributes(should_contact_parent1: true, should_contact_parent2: false, group_status: 'active')
      expect(Events::TextMessage.where(related: parent2, body: 'STOP').count).to eq(1)
    end

    it "arrête l'enfant quand le parent 1 répond STOP et que le parent 2 n'était plus à contacter" do
      parent1 = FactoryBot.create(:parent, phone_number: '+33611111111')
      parent2 = FactoryBot.create(:parent, phone_number: '+33622222222')
      child = FactoryBot.create(
        :child,
        parent1: parent1, parent2: parent2, should_contact_parent2: false,
        group: FactoryBot.create(:group), group_status: 'active'
      )

      subject.perform_now(stop_payload(phone_number: '+33611111111'))

      expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'stopped')
    end

    it 'applique le STOP en réponse à une campagne envoyée à la main depuis Spot-Hit' do
      parent = FactoryBot.create(:parent, phone_number: '+33612345678')
      child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'active')

      subject.perform_now(stop_payload(phone_number: '+33612345678', campaign_id: '99999'))

      expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'stopped')
      expect(Events::TextMessage.where(related: parent, body: 'STOP').count).to eq(1)
    end

    it 'applique le STOP reçu sans campagne' do
      parent = FactoryBot.create(:parent, phone_number: '+33612345678')
      child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'active')

      subject.perform_now(stop_payload(phone_number: '+33612345678', campaign_id: nil))

      expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'stopped')
      expect(Events::TextMessage.where(related: parent, body: 'STOP').count).to eq(1)
    end

    it "applique le STOP reçu sans date et le date de son traitement par l'app" do
      travel_to Time.zone.local(2026, 11, 18, 10, 5)
      parent = FactoryBot.create(:parent, phone_number: '+33612345678')
      child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'active')

      subject.perform_now(stop_payload(phone_number: '+33612345678', on: nil))

      expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'stopped', group_end: Date.new(2026, 11, 18))
      expect(Events::TextMessage.find_by(related: parent, body: 'STOP').occurred_at).to eq(Time.zone.local(2026, 11, 18, 10, 5))
    end

    it "historise un STOP rejoué sans changer le statut ni la fin de cohorte de l'enfant" do
      travel_to Time.zone.local(2026, 11, 18, 10)
      parent = FactoryBot.create(:parent, phone_number: '+33612345678')
      child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'active')
      subject.perform_now(stop_payload(phone_number: '+33612345678'))
      travel_to Time.zone.local(2026, 11, 19, 10)

      subject.perform_now(stop_payload(phone_number: '+33612345678', on: '2026-11-19T09:00:00Z'))

      expect(Events::TextMessage.where(related: parent, body: 'STOP').count).to eq(2)
      expect(child.reload).to have_attributes(group_status: 'stopped', group_end: Date.new(2026, 11, 18))
    end

    it "ignore sans alerte un STOP venant d'un numéro absent de la base" do
      expect(Rollbar).not_to receive(:error)

      expect do
        subject.perform_now(stop_payload(phone_number: '+33700000000'))
      end.not_to change(Events::TextMessage, :count)
    end

    it 'historise une réponse écrite contenant « stop » sans décocher le parent' do
      parent = FactoryBot.create(:parent, phone_number: '+33612345678')
      child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'active')
      response = {
        'events' => [
          {
            'on' => '2026-11-18T09:00:00Z',
            'userMessageReceived' => {
              'channelId' => 'rcs',
              'userId' => '+33612345678',
              'context' => { 'campaign_id' => '45878' },
              'content' => { 'text' => 'stop merci' }
            }
          }
        ]
      }

      subject.perform_now(response)

      expect(child.reload).to have_attributes(should_contact_parent1: true, group_status: 'active')
      expect(Events::TextMessage.where(related: parent, body: 'stop merci', originated_by_app: false).count).to eq(1)
    end
  end
end
