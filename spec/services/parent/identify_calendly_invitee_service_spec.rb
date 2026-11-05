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
      it 'renvoie une erreur quand utm_content est absent' do
        tracking = { 'utm_campaign' => 'call1', 'utm_content' => nil }

        service = described_class.new(invitee_payload: invitee_payload(tracking)).call

        expect(service.parent).to be_nil
        expect(service.errors).to eq(
          [{ message: 'Le security_token (utm_content) est manquant dans le payload', tracking: tracking }]
        )
      end

      it 'renvoie une erreur quand le payload ne contient pas de tracking' do
        service = described_class.new(invitee_payload: { 'event' => 'https://api.calendly.com/scheduled_events/RDV-1' }).call

        expect(service.parent).to be_nil
        expect(service.errors).to eq(
          [{ message: 'Le security_token (utm_content) est manquant dans le payload', tracking: {} }]
        )
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
