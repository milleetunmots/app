require 'rails_helper'

RSpec.describe BlockedSendAttempt::CreateTaskService do
  let_it_be(:assignee) { FactoryBot.create(:admin_user, user_role: 'super_admin', email: ENV.fetch('BLOCKED_SEND_ASSIGNEE_EMAIL')) }
  let(:author) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:attempt) do
    FactoryBot.create(
      :blocked_send_attempt,
      admin_user: author,
      message_body: 'Rejoignez-nous sur https://exemple-non-autorise.fr'
    )
  end

  describe '#call' do
    it "crée la tâche de suivi assignée à l'équipe tech, avec l'auteur en reporter" do
      service = described_class.new(attempt: attempt).call

      expect(service.errors).to be_empty
      expect(service.task).to have_attributes(
        title: 'Envoi bloqué à vérifier',
        reporter: author,
        assignee: assignee,
        related: attempt,
        due_date: Time.zone.today,
        done_at: nil
      )
    end

    it 'reprend le texte du message sans nommer le contrôle déclenché' do
      task = described_class.new(attempt: attempt).call.task

      expect(task.description).to eq('Rejoignez-nous sur https://exemple-non-autorise.fr')
      expect(task.description).not_to match(/url|valeurs détectées/i)
    end

    # La description est rendue sans échappement sur la fiche de la tâche.
    it 'échappe le HTML du message et garde ses sauts de ligne' do
      attempt.update!(message_body: "Bonjour\n<script>alert(1)</script>")

      task = described_class.new(attempt: attempt).call.task

      expect(task.description).to eq('Bonjour<br>&lt;script&gt;alert(1)&lt;/script&gt;')
    end

    context "quand le compte assigné n'existe pas" do
      around do |example|
        previous = ENV.fetch('BLOCKED_SEND_ASSIGNEE_EMAIL', nil)
        ENV['BLOCKED_SEND_ASSIGNEE_EMAIL'] = 'inconnu@example.com'
        example.run
        ENV['BLOCKED_SEND_ASSIGNEE_EMAIL'] = previous
      end

      it 'crée quand même la tâche, sans assigné, et le signale' do
        service = described_class.new(attempt: attempt).call

        expect(service.task).to be_persisted
        expect(service.task.assignee).to be_nil
        expected_error = {
          message: 'Le compte assigné aux envois bloqués est introuvable',
          context: { blocked_send_attempt_id: attempt.id, email: 'inconnu@example.com' }
        }
        expect(service.errors).to eq([expected_error])
      end
    end

    context "quand la variable d'assigné est absente" do
      around do |example|
        previous = ENV.delete('BLOCKED_SEND_ASSIGNEE_EMAIL')
        example.run
        ENV['BLOCKED_SEND_ASSIGNEE_EMAIL'] = previous
      end

      it 'crée quand même la tâche, sans assigné, et le signale' do
        service = described_class.new(attempt: attempt).call

        expect(service.task.assignee).to be_nil
        expect(service.errors.first[:message]).to eq('Le compte assigné aux envois bloqués est introuvable')
      end
    end

    context 'quand la tâche ne peut pas être enregistrée' do
      before do
        invalid_task = Task.new
        invalid_task.errors.add(:base, 'invalide')
        allow(Task).to receive(:create).and_return(invalid_task)
      end

      it "ne renvoie pas de tâche et rapporte l'échec" do
        service = described_class.new(attempt: attempt).call

        expect(service.task).to be_nil
        expect(service.errors).to include(
          {
            message: "La tâche de l'envoi bloqué n'a pas pu être créée",
            context: { blocked_send_attempt_id: attempt.id, errors: ['invalide'] }
          }
        )
      end
    end
  end
end
