require 'rails_helper'

RSpec.describe BlockedSendAttempt::SendGuard do
  around do |example|
    previous = %w[URL_FILTER_BLOCKING_ENABLED KEYWORD_FILTER_BLOCKING_ENABLED PHONE_NUMBER_FILTER_BLOCKING_ENABLED].index_with { |flag| ENV[flag] }
    previous.each_key { |flag| ENV[flag] = 'true' }
    example.run
    previous.each { |flag, value| value.nil? ? ENV.delete(flag) : ENV[flag] = value }
  end

  it 'bloque et trace kind url quand seule une URL non whitelistée est détectée' do
    guard = described_class.new('Voir https://non-whitelisted.example.com/page', provider: 'spothit')

    expect(guard.block_send?).to be(true)
    expect { guard.register! }.to change(BlockedSendAttempt, :count).by(1)
    expect(BlockedSendAttempt.last.kind).to eq('url')
  end

  it 'bloque et trace kind keyword quand seul un terme interdit est détecté' do
    FactoryBot.create(:blocked_pattern, value: 'virement')
    guard = described_class.new('Faites un virement rapidement', provider: 'spothit')

    expect(guard.block_send?).to be(true)
    expect { guard.register! }.to change(BlockedSendAttempt, :count).by(1)
    expect(BlockedSendAttempt.last.kind).to eq('keyword')
  end

  it 'bloque et trace kind phone_number quand seul un numéro surtaxé est détecté' do
    guard = described_class.new('Appelez le 0890 12 34 56', provider: 'spothit')

    expect(guard.block_send?).to be(true)
    expect { guard.register! }.to change(BlockedSendAttempt, :count).by(1)
    expect(BlockedSendAttempt.last.kind).to eq('phone_number')
  end

  it 'crée un attempt par kind quand URL et terme sont détectés ensemble' do
    FactoryBot.create(:blocked_pattern, value: 'virement')
    guard = described_class.new('virement ici : https://non-whitelisted.example.com/page', provider: 'spothit')

    expect { guard.register! }.to change(BlockedSendAttempt, :count).by(2)
    expect(BlockedSendAttempt.order(:id).last(2).map(&:kind)).to contain_exactly('url', 'keyword')
  end

  it "rattache chaque tentative tracée à l'auteur de l'envoi" do
    author = FactoryBot.create(:admin_user, user_role: 'caller')
    FactoryBot.create(:blocked_pattern, value: 'virement')
    guard = described_class.new('virement ici : https://non-whitelisted.example.com/page', provider: 'spothit', admin_user_id: author.id)

    attempts = guard.register!

    expect(attempts.map(&:admin_user_id)).to eq([author.id, author.id])
  end

  it "laisse la tentative sans auteur quand l'envoi est automatique" do
    guard = described_class.new('Voir https://non-whitelisted.example.com/page', provider: 'spothit')

    expect(guard.register!.map(&:admin_user_id)).to eq([nil])
  end

  it 'expose le nombre de destinataires de l\'envoi' do
    guard = described_class.new('Voir https://non-whitelisted.example.com/page', provider: 'spothit', recipients_count: 40)

    expect(guard.recipients_count).to eq(40)
  end

  it "expose un message d'erreur générique qui ne révèle ni la cause ni les valeurs" do
    guard = described_class.new('peu importe', provider: 'spothit')

    expect(guard.error_message).to eq("Ce message n'a pas pu être envoyé : le pôle tech va le vérifier. Vous serez prévenu(e) dans vos tâches dès que ce sera fait.")
  end

  describe 'tâche de suivi' do
    let_it_be(:assignee) { FactoryBot.create(:admin_user, user_role: 'super_admin', email: ENV.fetch('BLOCKED_SEND_ASSIGNEE_EMAIL')) }
    let(:author) { FactoryBot.create(:admin_user, user_role: 'caller') }
    let(:blocked_text) { 'Voir https://non-whitelisted.example.com/page' }
    let(:replay_params) { { 'message' => blocked_text, 'recipients' => ['parent.1'] } }

    def guard_for(text = blocked_text, admin_user_id: author.id)
      described_class.new(text, provider: 'spothit', replay_params: replay_params, admin_user_id: admin_user_id)
    end

    def register(text = blocked_text, admin_user_id: author.id)
      guard = guard_for(text, admin_user_id: admin_user_id)
      guard.register!
      guard
    end

    it "crée une tâche pour l'auteur et la cite dans le message d'erreur" do
      guard = nil
      expect { guard = register }.to change(Task, :count).by(1)

      task = Task.last
      expect(task).to have_attributes(reporter: author, assignee: assignee, related: BlockedSendAttempt.last)
      expect(guard.error_message).to eq("#{described_class::BLOCKED_MESSAGE} http://localhost:3000/admin/tasks/#{task.id}")
    end

    it 'crée une seule tâche quand le message déclenche deux contrôles' do
      FactoryBot.create(:blocked_pattern, value: 'virement')

      expect { register("virement ici : #{blocked_text}") }
        .to change(BlockedSendAttempt, :count).by(2)
        .and change(Task, :count).by(1)
    end

    [
      { kind: 'url', text: 'Voir exemple-bloque.fr', value: 'exemple-bloque.fr' },
      { kind: 'keyword', text: 'Une carte cadeau pour vous', value: 'carte cadeau' },
      { kind: 'phone_number', text: 'Appelez le 0890 12 34 56', value: '0890 12 34 56' }
    ].each do |example|
      it "donne le même message, sans la valeur détectée, pour un blocage de type #{example[:kind]}" do
        FactoryBot.create(:blocked_pattern, value: 'carte cadeau') if example[:kind] == 'keyword'

        guard = register(example[:text])

        expect(BlockedSendAttempt.last.kind).to eq(example[:kind])
        expect(guard.error_message).to start_with(described_class::BLOCKED_MESSAGE)
        expect(guard.error_message).to end_with("/admin/tasks/#{Task.last.id}")
        expect(guard.error_message).not_to include(example[:value])
      end
    end

    it "renvoie vers la tâche déjà ouverte quand l'auteur renvoie le même message" do
      first_task = register && Task.last

      guard = nil
      expect { guard = register }.not_to change(Task, :count)
      expect(guard.error_message).to end_with("/admin/tasks/#{first_task.id}")
    end

    it "ne crée pas de tâche pour un envoi automatique, et n'ajoute pas de lien" do
      guard = nil
      expect { guard = register(admin_user_id: nil) }.not_to change(Task, :count)
      expect(guard.error_message).to eq(described_class::BLOCKED_MESSAGE)
    end

    it 'ne crée pas de tâche en mode surveillance : le message est parti' do
      ENV['URL_FILTER_BLOCKING_ENABLED'] = ''

      expect { register }.not_to change(Task, :count)
      expect(BlockedSendAttempt.last.status).to eq('not_blocked')
    end

    it 'ne crée ni tentative ni tâche lors d\'une relance forcée' do
      attempt = FactoryBot.create(:blocked_send_attempt, force_send: true, admin_user: author)
      guard = described_class.new(blocked_text, provider: 'spothit', blocked_send_attempt_id: attempt.id, admin_user_id: author.id)

      expect { guard.register! }.not_to(change { [BlockedSendAttempt.count, Task.count] })
    end

    it "bloque quand même et rapporte l'échec quand la tâche ne peut pas être créée" do
      invalid_task = Task.new
      invalid_task.errors.add(:base, 'invalide')
      allow(Task).to receive(:create).and_return(invalid_task)
      allow(Rollbar).to receive(:error)

      guard = register

      expect(guard.block_send?).to be(true)
      expect(BlockedSendAttempt.last.status).to eq('pending')
      expect(guard.error_message).to eq(described_class::BLOCKED_MESSAGE)
      expect(Rollbar).to have_received(:error).with('BlockedSendAttempt::ReportService', errors: array_including(hash_including(message: "La tâche de l'envoi bloqué n'a pas pu être créée")))
    end

    describe 'alerte Slack' do
      let(:slack) { instance_double(BlockedSendAttempt::NotifySlackService, errors: []) }

      before do
        allow(slack).to receive(:call).and_return(slack)
        allow(BlockedSendAttempt::NotifySlackService).to receive(:new).and_return(slack)
      end

      it "alerte une fois pour l'envoi, avec la tâche et le nombre de destinataires" do
        FactoryBot.create(:blocked_pattern, value: 'virement')
        guard = described_class.new("virement ici : #{blocked_text}", provider: 'spothit', admin_user_id: author.id, recipients_count: 40)

        attempts = guard.register!

        expect(BlockedSendAttempt::NotifySlackService)
          .to have_received(:new).once.with(attempts: match_array(attempts), recipients_count: 40, task: Task.last)
      end

      it 'alerte aussi pour un envoi automatique, sans tâche' do
        register(admin_user_id: nil)

        expect(BlockedSendAttempt::NotifySlackService).to have_received(:new).with(hash_including(task: nil))
      end

      it "n'alerte pas de nouveau quand l'auteur renvoie le même message" do
        register
        register

        expect(BlockedSendAttempt::NotifySlackService).to have_received(:new).once
      end

      it "n'alerte pas en mode surveillance" do
        ENV['URL_FILTER_BLOCKING_ENABLED'] = ''

        register

        expect(BlockedSendAttempt::NotifySlackService).not_to have_received(:new)
      end

      it "n'alerte pas lors d'une relance forcée" do
        attempt = FactoryBot.create(:blocked_send_attempt, force_send: true)

        described_class.new(blocked_text, provider: 'spothit', blocked_send_attempt_id: attempt.id).register!

        expect(BlockedSendAttempt::NotifySlackService).not_to have_received(:new)
      end

      it "bloque quand même et rapporte l'échec de l'alerte" do
        errors = [{ message: "L'alerte Slack de l'envoi bloqué n'a pas pu être postée", context: {} }]
        allow(slack).to receive(:errors).and_return(errors)
        allow(Rollbar).to receive(:error)

        guard = register

        expect(guard.block_send?).to be(true)
        expect(guard.error_message).to end_with("/admin/tasks/#{Task.last.id}")
        expect(Rollbar).to have_received(:error).with('BlockedSendAttempt::ReportService', errors: errors)
      end
    end

    # Création d'atelier : l'envoi a lieu dans une transaction que l'appelant
    # annule, il signale lui-même l'envoi bloqué après son rollback.
    it 'ne crée ni tâche ni alerte quand le signalement est différé, mais expose les tentatives' do
      allow(BlockedSendAttempt::NotifySlackService).to receive(:new).and_call_original
      guard = described_class.new(blocked_text, provider: 'spothit', admin_user_id: author.id, defer_report: true)

      attempts = nil
      expect { attempts = guard.register! }.not_to change(Task, :count)

      expect(guard.blocked_attempts).to eq(attempts)
      expect(guard.error_message).to eq(described_class::BLOCKED_MESSAGE)
      expect(BlockedSendAttempt::NotifySlackService).not_to have_received(:new)
    end

    it 'garde le blocage et retire le lien quand l\'URL de la tâche ne peut être construite' do
      allow(Rails.application.routes.url_helpers).to receive(:admin_task_url).and_raise(ArgumentError, 'Missing host')
      allow(Rollbar).to receive(:error)

      guard = register

      expect(guard.error_message).to eq(described_class::BLOCKED_MESSAGE)
      expect(Rollbar).to have_received(:error).with('BlockedSendAttempt::SendGuard lien de tâche', errors: ['Missing host'])
    end
  end

  it "en relance d'un attempt url, ne re-trace pas l'url mais trace un terme nouvellement blacklisté" do
    url_attempt = FactoryBot.create(:blocked_send_attempt, kind: 'url')
    FactoryBot.create(:blocked_pattern, value: 'virement')
    guard = described_class.new(
      'virement ici : https://non-whitelisted.example.com/page',
      provider: 'spothit',
      blocked_send_attempt_id: url_attempt.id
    )

    expect { guard.register! }.to change(BlockedSendAttempt, :count).by(1)
    expect(BlockedSendAttempt.last.kind).to eq('keyword')
  end

  # Une relance décidée par un super_admin est un feu vert humain sur un contenu
  # déjà relu dans l'admin : plus aucun contrôle ne doit la bloquer.
  context 'en relance forcée par un admin (force_send)' do
    it "ne bloque pas, même quand l'URL est toujours interdite" do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'url', force_send: true)
      guard = described_class.new(
        'Voir https://non-whitelisted.example.com/page',
        provider: 'spothit',
        blocked_send_attempt_id: attempt.id
      )

      expect(guard.blocked?).to be(false)
      expect(guard.block_send?).to be(false)
    end

    it "ne bloque pas non plus sur une cause nouvelle d'un autre kind" do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'url', force_send: true)
      FactoryBot.create(:blocked_pattern, value: 'virement')
      guard = described_class.new(
        'virement ici : https://non-whitelisted.example.com/page',
        provider: 'spothit',
        blocked_send_attempt_id: attempt.id
      )

      expect(guard.block_send?).to be(false)
      expect { guard.register! }.not_to change(BlockedSendAttempt, :count)
    end

    it 'bloque toujours quand la tentative référencée ne force pas (mode surveillance)' do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'keyword', status: 'not_blocked')
      guard = described_class.new(
        'Voir https://non-whitelisted.example.com/page',
        provider: 'spothit',
        blocked_send_attempt_id: attempt.id
      )

      expect(guard.block_send?).to be(true)
    end
  end
end
