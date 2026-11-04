require 'rails_helper'

RSpec.describe BlockedSendAttempt::ResolveTaskService do
  let(:super_admin) { FactoryBot.create(:admin_user, user_role: 'super_admin') }
  let(:author) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:attempt) { FactoryBot.create(:blocked_send_attempt, admin_user: author) }
  let!(:task) { BlockedSendAttempt::CreateTaskService.new(attempt: attempt).call.task }
  let(:today) { Time.zone.today.strftime('%d/%m/%Y') }

  describe '#call' do
    it "clôt la tâche d'un envoi relancé en disant que le message est parti" do
      service = described_class.new(attempt: attempt, outcome: :relaunched, admin_user: super_admin).call

      expect(service.errors).to be_empty
      expect(task.reload).to have_attributes(status: 'done', done_at: Time.zone.today, treated_by: super_admin)
      expect(task.description).to end_with("<br><br>Relancé le #{today} : le message a été envoyé.")
      expect(task.description).to start_with(ERB::Util.html_escape(attempt.message_body))
    end

    it "clôt la tâche d'un envoi archivé en disant que le message n'est pas parti" do
      described_class.new(attempt: attempt, outcome: :archived, admin_user: super_admin).call

      expect(task.reload.status).to eq('done')
      expect(task.description).to end_with("Non relancé : le message n'a pas été envoyé (archivé le #{today}).")
    end

    it "clôt aussi la tâche quand on traite la tentative sœur à laquelle elle n'est pas liée" do
      sibling = FactoryBot.create(:blocked_send_attempt, kind: 'keyword', detected_values: ['carte cadeau'])

      described_class.new(attempt: sibling, outcome: :relaunched, admin_user: super_admin).call

      expect(task.reload.status).to eq('done')
    end

    it "ne touche pas la tâche d'un autre envoi" do
      other_attempt = FactoryBot.create(:blocked_send_attempt, message_body: 'Autre message')

      described_class.new(attempt: other_attempt, outcome: :relaunched).call

      expect(task.reload.done_at).to be_nil
    end

    it 'ne fait rien pour une tentative sans tâche (envoi automatique, tentative antérieure)' do
      other_attempt = FactoryBot.create(:blocked_send_attempt, message_body: 'Autre message')

      service = described_class.new(attempt: other_attempt, outcome: :archived).call

      expect(service.errors).to be_empty
    end

    it "ne rouvre pas une tâche déjà close et n'y ajoute rien" do
      described_class.new(attempt: attempt, outcome: :relaunched, admin_user: super_admin).call
      description = task.reload.description

      described_class.new(attempt: attempt, outcome: :archived, admin_user: super_admin).call

      expect(task.reload.description).to eq(description)
    end

    it 'ignore une tâche supprimée par un admin' do
      task.discard

      service = described_class.new(attempt: attempt, outcome: :relaunched, admin_user: super_admin).call

      expect(service.errors).to be_empty
      expect(task.reload.done_at).to be_nil
    end

    it "rapporte l'échec sans lever quand la tâche ne peut pas être enregistrée" do
      allow_any_instance_of(Task).to receive(:update).and_return(false)

      service = described_class.new(attempt: attempt, outcome: :relaunched, admin_user: super_admin).call

      expect(service.errors.first).to include(
        message: "La tâche de l'envoi bloqué n'a pas pu être close",
        context: hash_including(task_id: task.id, blocked_send_attempt_id: attempt.id)
      )
    end
  end
end
