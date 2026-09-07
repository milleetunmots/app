require 'rails_helper'

RSpec.describe Slack::PostMessageService, type: :service do
  # Un identifiant de canal est envoyé tel quel par le gem : pas de résolution
  # de nom, donc un seul appel HTTP à observer.
  describe '#call' do
    it 'poste le message dans le canal' do
      described_class.new(channel: 'C0TEST', text: 'Coucou').call

      expect(WebMock).to have_requested(:post, 'https://slack.com/api/chat.postMessage')
        .with { |request| request.body.include?('channel=C0TEST') && request.body.include?('Coucou') }
    end

    it "publie le message sous l'emoji demandé" do
      described_class.new(channel: 'C0TEST', text: 'Coucou', icon_emoji: ':rotating_light:').call

      expect(WebMock).to have_requested(:post, 'https://slack.com/api/chat.postMessage')
        .with { |request| CGI.unescape(request.body).include?('icon_emoji=:rotating_light:') }
    end

    it "publie le message sous le nom demandé" do
      described_class.new(channel: 'C0TEST', text: 'Coucou', username: 'Alerte quota message').call

      expect(WebMock).to have_requested(:post, 'https://slack.com/api/chat.postMessage')
        .with { |request| CGI.unescape(request.body).include?('username=Alerte quota message') }
    end

    it "n'envoie ni icon_emoji ni username quand ils ne sont pas fournis" do
      described_class.new(channel: 'C0TEST', text: 'Coucou').call

      expect(WebMock).to have_requested(:post, 'https://slack.com/api/chat.postMessage')
        .with { |request| !request.body.include?('icon_emoji') && !request.body.include?('username') }
    end

    it 'retourne le service et ne signale aucune erreur' do
      service = described_class.new(channel: 'C0TEST', text: 'Coucou').call

      expect(service).to be_a(described_class)
      expect(service.errors).to be_empty
    end

    # `chat_postMessage` transmet le canal tel quel — contrairement à
    # `chat_update` ou `chat_delete`, il ne résout pas un nom en identifiant via
    # `conversations.list` : c'est l'API Slack qui accepte les deux formes.
    it 'transmet un canal désigné par son nom sans le résoudre' do
      described_class.new(channel: '#test_app', text: 'Coucou').call

      expect(WebMock).not_to have_requested(:post, 'https://slack.com/api/conversations.list')
      expect(WebMock).to have_requested(:post, 'https://slack.com/api/chat.postMessage')
        .with { |request| CGI.unescape(request.body).include?('channel=#test_app') }
    end

    context 'quand Slack refuse le message' do
      before do
        stub_request(:post, 'https://slack.com/api/chat.postMessage')
          .to_return(
            status: 200,
            body: { ok: false, error: 'channel_not_found' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'expose l’erreur sans la lever' do
        service = nil

        expect { service = described_class.new(channel: 'C0TEST', text: 'Coucou').call }.not_to raise_error
        expect(service.errors.first).to include('C0TEST', 'channel_not_found')
      end
    end

    context 'quand Slack ne répond pas' do
      before { stub_request(:post, 'https://slack.com/api/chat.postMessage').to_timeout }

      it 'expose l’erreur sans la lever' do
        service = nil

        expect { service = described_class.new(channel: 'C0TEST', text: 'Coucou').call }.not_to raise_error
        expect(service.errors).not_to be_empty
      end
    end

    context 'quand le payload est invalide' do
      it "expose l'erreur sans la lever" do
        service = nil

        expect { service = described_class.new(channel: nil, text: nil).call }.not_to raise_error
        expect(service.errors).not_to be_empty
      end
    end
  end
end