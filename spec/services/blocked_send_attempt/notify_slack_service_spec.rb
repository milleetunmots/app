require 'rails_helper'

RSpec.describe BlockedSendAttempt::NotifySlackService do
  let(:slack) { instance_double(Slack::PostMessageService, errors: []) }
  let(:alerts) { [] }
  let(:routes) { Rails.application.routes.url_helpers }
  let(:author) { FactoryBot.create(:admin_user, user_role: 'caller', name: 'Awa') }
  let(:attempt) do
    FactoryBot.create(:blocked_send_attempt, admin_user: author, kind: 'url', detected_values: ['https://exemple-non-autorise.fr'])
  end

  before do
    allow(slack).to receive(:call).and_return(slack)
    allow(Slack::PostMessageService).to receive(:new) do |payload|
      alerts << payload
      slack
    end
  end

  def alert_content
    alerts.last[:text]
  end

  describe '#call' do
    it "poste dans le canal des envois bloqués, sous l'identité d'alerte" do
      service = described_class.new(attempts: [attempt]).call

      expect(service.errors).to be_empty
      expect(alerts.last).to include(
        channel: "##{ENV.fetch('SLACK_BLOCKED_SEND_ALERT_CHANNEL')}",
        icon_emoji: described_class::ALERT_ICON_EMOJI,
        username: described_class::ALERT_USERNAME
      )
    end

    it "décrit l'envoi : auteur, fournisseur, destinataires, contrôle, valeurs et tentative" do
      described_class.new(attempts: [attempt], recipients_count: 40).call

      expect(alert_content).to include(
        "*Auteur* : <#{routes.admin_admin_user_url(id: author.id)}|Awa>",
        '*Fournisseur* : spothit',
        '*Destinataires* : 40 familles',
        '*Contrôle(s)* : URL',
        '*Valeurs détectées* : https://exemple-non-autorise.fr',
        "*Tentative(s)* : <#{routes.admin_blocked_send_attempt_url(id: attempt.id)}|n° #{attempt.id}>"
      )
    end

    it 'accorde le nombre de destinataires au singulier' do
      described_class.new(attempts: [attempt], recipients_count: 1).call

      expect(alert_content).to include('*Destinataires* : 1 famille')
    end

    it "omet la ligne des destinataires quand l'envoi n'en a pas (modèle RCS)" do
      described_class.new(attempts: [attempt]).call

      expect(alert_content).not_to include('*Destinataires*')
    end

    it 'lie la tâche de suivi quand elle existe' do
      task = FactoryBot.create(:task)

      described_class.new(attempts: [attempt], task: task).call

      expect(alert_content).to include("*Tâche* : <#{routes.admin_task_url(id: task.id)}|n° #{task.id}>")
    end

    it 'indique « envoi automatique » quand la tentative est sans auteur' do
      attempt.update!(admin_user: nil)

      described_class.new(attempts: [attempt]).call

      expect(alert_content).to include('*Auteur* : envoi automatique')
      expect(alert_content).not_to include('*Tâche*')
    end

    it "réunit les tentatives d'un même envoi dans une seule alerte" do
      keyword_attempt = FactoryBot.create(:blocked_send_attempt, admin_user: author, kind: 'keyword', detected_values: ['carte cadeau'])

      described_class.new(attempts: [attempt, keyword_attempt]).call

      expect(alerts.size).to eq(1)
      expect(alert_content).to include('*Contrôle(s)* : URL, Mot-clé', 'https://exemple-non-autorise.fr, carte cadeau')
    end

    # Un envoi de masse détecte une valeur par destinataire : on ne recopie pas
    # dans Slack les données de toutes les familles.
    it 'plafonne et tronque les valeurs détectées' do
      long_value = "https://exemple.fr/#{'a' * 200}"
      values = [long_value] + Array.new(6) { |n| "https://lien#{n}.fr" }
      attempt.update!(detected_values: values)

      described_class.new(attempts: [attempt]).call

      expect(alert_content).to include('et 2 autres')
      expect(alert_content).not_to include('a' * 100)
      expect(alert_content).not_to include('https://lien5.fr')
    end

    it 'échappe les caractères qui casseraient la mise en forme Slack' do
      attempt.update!(detected_values: ['https://exemple.fr/?a=1&b=<2>'])

      described_class.new(attempts: [attempt]).call

      expect(alert_content).to include('https://exemple.fr/?a=1&amp;b=&lt;2&gt;')
    end

    it "rapporte l'échec de Slack sans lever" do
      allow(slack).to receive(:errors).and_return(['Slack chat.postMessage vers #test : timeout'])

      service = described_class.new(attempts: [attempt]).call

      expect(service.errors).to eq(
        [
          {
            message: "L'alerte Slack de l'envoi bloqué n'a pas pu être postée",
            context: { blocked_send_attempt_ids: [attempt.id], error: 'Slack chat.postMessage vers #test : timeout' }
          }
        ]
      )
    end

    context "quand le canal n'est pas configuré" do
      around do |example|
        previous = ENV.delete('SLACK_BLOCKED_SEND_ALERT_CHANNEL')
        example.run
        ENV['SLACK_BLOCKED_SEND_ALERT_CHANNEL'] = previous
      end

      it "n'appelle pas Slack et le signale" do
        service = described_class.new(attempts: [attempt]).call

        expect(Slack::PostMessageService).not_to have_received(:new)
        expect(service.errors.first[:message]).to eq("Le canal Slack des envois bloqués n'est pas configuré")
      end
    end

    it "poste l'alerte sans lien quand l'hôte de l'application n'est pas configuré" do
      allow(Rails.application.routes.url_helpers).to receive(:admin_blocked_send_attempt_url).and_raise(ArgumentError, 'Missing host')

      service = described_class.new(attempts: [attempt]).call

      expect(alert_content).to include("*Tentative(s)* : n° #{attempt.id}")
      expect(service.errors.first[:message]).to eq("Un lien de l'alerte Slack n'a pas pu être construit")
    end
  end
end
