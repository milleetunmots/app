require 'rails_helper'

RSpec.describe BlockedSendAttempt::ReportService do
  let_it_be(:assignee) { FactoryBot.create(:admin_user, user_role: 'super_admin', email: ENV.fetch('BLOCKED_SEND_ASSIGNEE_EMAIL')) }
  let(:author) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:slack) { instance_double(BlockedSendAttempt::NotifySlackService, errors: []) }

  before do
    allow(slack).to receive(:call).and_return(slack)
    allow(BlockedSendAttempt::NotifySlackService).to receive(:new).and_return(slack)
  end

  describe '#call' do
    it "crée la tâche de l'auteur puis alerte l'équipe en la citant" do
      attempt = FactoryBot.create(:blocked_send_attempt, admin_user: author)

      service = described_class.new(attempts: [attempt], recipients_count: 3).call

      expect(service.task).to have_attributes(reporter: author, related: attempt)
      expect(BlockedSendAttempt::NotifySlackService).to have_received(:new).with(attempts: [attempt], recipients_count: 3, task: service.task)
    end

    it "retrouve la tâche ouverte et n'alerte pas pour des tentatives déjà tracées" do
      attempt = FactoryBot.create(:blocked_send_attempt, admin_user: author)
      task = described_class.new(attempts: [attempt]).call.task

      service = described_class.new(attempts: [BlockedSendAttempt.find(attempt.id)]).call

      expect(service.task).to eq(task)
      expect(BlockedSendAttempt::NotifySlackService).to have_received(:new).once
    end

    it 'alerte sans tâche pour un envoi sans auteur' do
      attempt = FactoryBot.create(:blocked_send_attempt, admin_user: nil)

      service = described_class.new(attempts: [attempt]).call

      expect(service.task).to be_nil
      expect(BlockedSendAttempt::NotifySlackService).to have_received(:new).with(hash_including(task: nil))
    end

    it 'ne fait rien sans tentative' do
      service = described_class.new(attempts: []).call

      expect(service.task).to be_nil
      expect(BlockedSendAttempt::NotifySlackService).not_to have_received(:new)
    end

    it 'réunit les erreurs de la tâche et de l’alerte' do
      ENV['BLOCKED_SEND_ASSIGNEE_EMAIL'] = 'inconnu@example.com'
      slack_error = { message: "L'alerte Slack de l'envoi bloqué n'a pas pu être postée", context: {} }
      allow(slack).to receive(:errors).and_return([slack_error])
      attempt = FactoryBot.create(:blocked_send_attempt, admin_user: author)

      service = described_class.new(attempts: [attempt]).call

      expect(service.errors.pluck(:message))
        .to eq(['Le compte assigné aux envois bloqués est introuvable', slack_error[:message]])
    ensure
      ENV['BLOCKED_SEND_ASSIGNEE_EMAIL'] = assignee.email
    end
  end
end
