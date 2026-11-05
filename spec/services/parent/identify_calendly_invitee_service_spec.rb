require 'rails_helper'

RSpec.describe Parent::IdentifyCalendlyInviteeService do
  def invitee_payload(tracking)
    { 'event' => 'https://api.calendly.com/scheduled_events/RDV-1', 'tracking' => tracking }
  end

  describe '#call' do
    context 'avec un jeton connu' do
      it 'identifie le parent et la session du lien' do
        parent = FactoryBot.create(:parent)
        payload = invitee_payload('utm_campaign' => 'call2', 'utm_content' => parent.security_token)

        service = described_class.new(invitee_payload: payload).call

        expect(service.errors).to be_empty
        expect(service.parent).to eq(parent)
        expect(service.call_session).to eq(2)
      end

      it 'ignore les caractères non alphanumériques ajoutés au jeton' do
        parent = FactoryBot.create(:parent)
        payload = invitee_payload('utm_campaign' => 'call1', 'utm_content' => "#{parent.security_token}.")

        service = described_class.new(invitee_payload: payload).call

        expect(service.parent).to eq(parent)
      end
    end

    context 'sans jeton' do
      it "renvoie une erreur avec le contexte du RDV quand aucun parent n'est identifié" do
        payload = invitee_payload('utm_campaign' => nil, 'utm_content' => nil).merge(
          'scheduled_event' => {
            'event_type' => 'https://api.calendly.com/event_types/INCONNU',
            'event_memberships' => [{ 'user' => 'https://api.calendly.com/users/AWA' }]
          }
        )

        service = described_class.new(invitee_payload: payload).call

        expect(service.parent).to be_nil
        expect(service.errors).to eq(
          [{
            message: 'Aucun parent identifié pour ce RDV',
            context: {
              event_uri: 'https://api.calendly.com/scheduled_events/RDV-1',
              event_type_uri: 'https://api.calendly.com/event_types/INCONNU',
              host_uris: ['https://api.calendly.com/users/AWA'],
              security_token: nil
            }
          }]
        )
      end

      it 'renvoie la même erreur quand le payload ne contient ni tracking ni scheduled_event' do
        service = described_class.new(invitee_payload: { 'event' => 'https://api.calendly.com/scheduled_events/RDV-1' }).call

        expect(service.parent).to be_nil
        expect(service.errors).to contain_exactly(hash_including(message: 'Aucun parent identifié pour ce RDV'))
      end

      it 'traite un jeton vide après nettoyage comme absent' do
        FactoryBot.create(:parent)

        service = described_class.new(invitee_payload: invitee_payload('utm_content' => '--')).call

        expect(service.parent).to be_nil
        expect(service.errors).to contain_exactly(hash_including(message: 'Aucun parent identifié pour ce RDV'))
      end
    end

    context 'avec un jeton tronqué' do
      it 'identifie le seul parent dont le jeton commence par ce morceau' do
        parent = FactoryBot.create(:parent, security_token: '3f9a1c0b7d2e4f6a8b9c0d1e2f3a4b5c')
        FactoryBot.create(:parent, security_token: '3c5e7a9b1d2f4a6c8e0b2d4f6a8c0e1a')
        payload = invitee_payload('utm_campaign' => 'call1', 'utm_content' => '3f')

        service = described_class.new(invitee_payload: payload).call

        expect(service.errors).to be_empty
        expect(service.parent).to eq(parent)
        expect(service.call_session).to eq(1)
      end

      it "n'identifie personne quand plusieurs jetons commencent par ce morceau" do
        FactoryBot.create(:parent, security_token: '3f9a1c0b7d2e4f6a8b9c0d1e2f3a4b5c')
        FactoryBot.create(:parent, security_token: '3c5e7a9b1d2f4a6c8e0b2d4f6a8c0e1a')

        service = described_class.new(invitee_payload: invitee_payload('utm_content' => '3')).call

        expect(service.parent).to be_nil
        expect(service.errors).to contain_exactly(hash_including(message: 'Aucun parent identifié pour ce RDV'))
      end

      it 'ignore les parents archivés' do
        FactoryBot.create(:parent, security_token: '3f9a1c0b7d2e4f6a8b9c0d1e2f3a4b5c').discard

        service = described_class.new(invitee_payload: invitee_payload('utm_content' => '3f9a1c')).call

        expect(service.parent).to be_nil
        expect(service.errors).to contain_exactly(hash_including(message: 'Aucun parent identifié pour ce RDV'))
      end

      it 'traite les caractères spéciaux SQL comme du texte' do
        FactoryBot.create(:parent, security_token: '3f9a1c0b7d2e4f6a8b9c0d1e2f3a4b5c')

        service = described_class.new(invitee_payload: invitee_payload('utm_content' => '%')).call

        expect(service.parent).to be_nil
      end
    end

    context 'avec un jeton inconnu' do
      it 'renvoie une erreur avec le jeton recherché' do
        payload = invitee_payload('utm_campaign' => 'call1', 'utm_content' => 'ffffffffffffffffffffffffffffffff')

        service = described_class.new(invitee_payload: payload).call

        expect(service.parent).to be_nil
        expect(service.errors).to eq(
          [{ message: 'Aucun parent trouvé avec le security_token', security_token: 'ffffffffffffffffffffffffffffffff' }]
        )
      end
    end

    context 'selon utm_campaign' do
      [['call0', 0], ['call3', 3], ['autre', nil], [nil, nil]].each do |utm_campaign, expected_session|
        it "déduit la session #{expected_session.inspect} de #{utm_campaign.inspect}" do
          parent = FactoryBot.create(:parent)
          payload = invitee_payload('utm_campaign' => utm_campaign, 'utm_content' => parent.security_token)

          service = described_class.new(invitee_payload: payload).call

          expect(service.call_session).to eq(expected_session)
        end
      end
    end
  end
end
