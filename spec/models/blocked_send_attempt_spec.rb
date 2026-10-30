# == Schema Information
#
# Table name: blocked_send_attempts
#
#  id              :bigint           not null, primary key
#  detected_values :string           default([]), not null, is an Array
#  force_send      :boolean          default(FALSE), not null
#  kind            :string           not null
#  message_body    :text             not null
#  provider        :string           not null
#  replay_params   :jsonb            not null
#  resolved_at     :datetime
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  admin_user_id   :bigint
#
# Indexes
#
#  index_blocked_send_attempts_on_admin_user_id  (admin_user_id)
#  index_blocked_send_attempts_on_status         (status)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#
require 'rails_helper'

RSpec.describe BlockedSendAttempt do
  around do |example|
    previous = ENV['URL_FILTER_BLOCKING_ENABLED']
    ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
    example.run
    ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
  end

  let_it_be(:parent, reload: true) { FactoryBot.create(:parent) }
  let_it_be(:group, reload: true) { FactoryBot.create(:group) }
  let_it_be(:child, reload: true) do
    FactoryBot.create(:child, parent1_id: parent.id, should_contact_parent1: true, group_id: group.id, group_status: 'active')
  end

  let(:blocked_url) { 'https://non-whitelisted.example.com/page' }
  let(:message) { "Cliquez ici : #{blocked_url}" }

  before do
    stub_request(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').
      to_return(status: 200, body: { success: true, campaign_id: '123' }.to_json)
  end

  def send_program_message!
    ProgramMessageService.new(
      Time.zone.today,
      Time.zone.now.strftime('%H:%M'),
      ["parent.#{parent.id}"],
      message
    ).call
  end

  describe 'validations' do
    it 'refuse un provider inconnu' do
      attempt = FactoryBot.build(:blocked_send_attempt, provider: 'pigeon-voyageur')

      expect(attempt).not_to be_valid
      expect(attempt.errors[:provider]).to be_present
    end

    it 'accepte les providers connus' do
      %w[spothit aircall].each do |provider|
        expect(FactoryBot.build(:blocked_send_attempt, provider: provider)).to be_valid
      end
    end

    it 'accepte le statut archived' do
      expect(FactoryBot.build(:blocked_send_attempt, status: 'archived')).to be_valid
    end

    it 'refuse un statut inconnu' do
      attempt = FactoryBot.build(:blocked_send_attempt, status: 'supprime')

      expect(attempt).not_to be_valid
      expect(attempt.errors[:status]).to be_present
    end
  end

  describe 'auteur' do
    it "est facultatif : un envoi automatique n'en a pas" do
      expect(FactoryBot.build(:blocked_send_attempt, admin_user: nil)).to be_valid
    end

    it 'est rattaché au compte qui a envoyé le message' do
      caller_user = FactoryBot.create(:admin_user, user_role: 'caller')
      attempt = FactoryBot.create(:blocked_send_attempt, admin_user: caller_user)

      expect(caller_user.blocked_send_attempts).to eq([attempt])
    end

    it 'est retiré, sans supprimer la tentative, quand le compte est supprimé' do
      caller_user = FactoryBot.create(:admin_user, user_role: 'caller')
      attempt = FactoryBot.create(:blocked_send_attempt, admin_user: caller_user)

      caller_user.destroy!

      expect(attempt.reload.admin_user_id).to be_nil
    end
  end

  describe '.same_message_as' do
    let(:attempt) { FactoryBot.create(:blocked_send_attempt, kind: 'url') }

    it 'retourne les tentatives du même envoi, sans la tentative elle-même' do
      sibling = FactoryBot.create(:blocked_send_attempt, kind: 'keyword', detected_values: ['carte cadeau'])

      expect(described_class.same_message_as(attempt)).to eq([sibling])
    end

    it "écarte une tentative d'un autre provider" do
      FactoryBot.create(:blocked_send_attempt, kind: 'keyword', detected_values: ['carte cadeau'], provider: 'aircall')

      expect(described_class.same_message_as(attempt)).to be_empty
    end

    it 'écarte une tentative au message différent' do
      FactoryBot.create(:blocked_send_attempt, kind: 'keyword', detected_values: ['carte cadeau'], message_body: 'Autre message')

      expect(described_class.same_message_as(attempt)).to be_empty
    end

    it 'écarte une tentative aux paramètres de relance différents' do
      FactoryBot.create(:blocked_send_attempt, kind: 'keyword', detected_values: ['carte cadeau'], replay_params: {})

      expect(described_class.same_message_as(attempt)).to be_empty
    end
  end

  describe 'un envoi contenant une URL non whitelistée' do
    it 'crée un BlockedSendAttempt pending et ne transmet pas le message au provider' do
      expect { send_program_message! }.to change(BlockedSendAttempt, :count).by(1)

      attempt = BlockedSendAttempt.last
      expect(attempt.status).to eq('pending')
      expect(attempt.provider).to eq('spothit')
      expect(attempt.detected_values).to eq([blocked_url])
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end
  end

  describe 'un admin technique relance un envoi bloqué depuis la console' do
    it "transmet réellement le message et passe le statut à relaunched une fois l'URL whitelistée" do
      send_program_message!
      attempt = BlockedSendAttempt.last
      FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'exact', value: blocked_url)

      service = attempt.relaunch!

      expect(service.errors).to be_empty
      expect(attempt.reload.status).to eq('relaunched')
      expect(attempt.resolved_at).to be_present
      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').once
    end
  end

  describe "un admin technique relance alors que l'URL n'est toujours pas whitelistée" do
    it 'transmet quand même le message : la relance est un feu vert humain qui court-circuite les contrôles' do
      send_program_message!
      attempt = BlockedSendAttempt.last

      expect { attempt.relaunch! }.not_to change(BlockedSendAttempt, :count)
      expect(attempt.reload.status).to eq('relaunched')
      expect(attempt.resolved_at).to be_present
      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').once
    end

    it "n'est pas bloqué non plus par un terme interdit ajouté après le blocage initial" do
      send_program_message!
      attempt = BlockedSendAttempt.last
      FactoryBot.create(:blocked_pattern, value: 'Regardez')

      attempt.relaunch!

      expect(attempt.reload.status).to eq('relaunched')
      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').once
    end
  end

  describe 'la relance vaut autorisation durable' do
    it "whiteliste l'URL détectée : le même lien passe ensuite sans blocage" do
      send_program_message!
      attempt = BlockedSendAttempt.last

      expect { attempt.relaunch! }.to change(AllowedPattern, :count).by(1)

      expect(AllowedPattern.last).to have_attributes(kind: 'url', match_type: 'exact', value: blocked_url)
      expect(attempt.whitelisted_values).to eq([blocked_url])
      expect { send_program_message! }.not_to change(BlockedSendAttempt, :count)
    end

    it 'ne whiteliste rien quand la relance échoue : la tentative reste à traiter' do
      attempt = FactoryBot.create(:blocked_send_attempt, replay_params: {})

      expect { attempt.relaunch! }.not_to change(AllowedPattern, :count)
      expect(attempt.reload.status).to eq('pending')
      expect(attempt.whitelisted_values).to eq([])
    end

    # Un message bloqué à la fois sur son URL et sur son numéro produit deux
    # tentatives : relancer l'une résout l'autre, autoriser l'une doit donc
    # autoriser l'autre — sinon le numéro rebloquerait le prochain envoi.
    context 'quand le message a été bloqué sur deux motifs' do
      around do |example|
        previous = ENV.fetch('PHONE_NUMBER_FILTER_BLOCKING_ENABLED', nil)
        ENV['PHONE_NUMBER_FILTER_BLOCKING_ENABLED'] = 'true'
        example.run
        ENV['PHONE_NUMBER_FILTER_BLOCKING_ENABLED'] = previous
      end

      let(:message) { "Cliquez ici : #{blocked_url} ou appelez le 0810 12 34 56" }

      it 'whiteliste aussi les valeurs de la tentative sœur résolue' do
        expect { send_program_message! }.to change(BlockedSendAttempt, :count).by(2)
        url_attempt = BlockedSendAttempt.find_by(kind: 'url')

        expect { url_attempt.relaunch! }.to change(AllowedPattern, :count).by(2)

        expect(url_attempt.whitelisted_values).to match_array([blocked_url, '0810123456'])
        expect(AllowedPattern.exists?(kind: 'phone_number', match_type: 'exact', value: '0810123456')).to be(true)
        expect(BlockedSendAttempt.find_by(kind: 'phone_number').status).to eq('relaunched')
      end
    end

    it 'ne whiteliste pas un mot-clé : le terme reste interdit' do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'keyword', detected_values: ['carte cadeau'])

      expect { attempt.relaunch! }.not_to change(AllowedPattern, :count)
      expect(attempt.whitelisted_values).to eq([])
    end
  end

  describe 'un envoi automatique enregistré sans paramètres de relance (replay_params vide)' do
    let(:attempt) { FactoryBot.create(:blocked_send_attempt, replay_params: {}) }

    it "n'est pas replayable" do
      expect(attempt.replayable?).to be(false)
    end

    it 'refuse la relance avec une erreur explicite au lieu de planter' do
      result = attempt.relaunch!

      expect(result.errors).to be_any
      expect(attempt.reload.status).to eq('pending')
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end
  end

  describe "un envoi bloqué qu'on ne relance jamais" do
    it 'reste indéfiniment pending sans action explicite' do
      send_program_message!

      expect(BlockedSendAttempt.last.status).to eq('pending')
    end
  end

  # La relance et l'archivage sont les deux issues d'une tentative à traiter :
  # une tentative déjà traitée ne repart jamais, même relancée depuis la console.
  describe 'une tentative déjà traitée' do
    %w[relaunched archived not_blocked].each do |status|
      it "refuse la relance d'une tentative #{status} sans rien retransmettre" do
        attempt = FactoryBot.create(:blocked_send_attempt, status: status, replay_params: { recipients: ["parent.#{parent.id}"], message: message })

        attempt.relaunch!

        expect(attempt.errors.full_messages).to eq([described_class::RELAUNCH_REFUSED_MESSAGE])
        expect(attempt.reload).to have_attributes(status: status, force_send: false)
        expect(WebMock).not_to have_requested(:post, %r{https://www\.spot-hit\.fr})
      end
    end
  end

  describe '#archive!' do
    let_it_be(:super_admin) { FactoryBot.create(:admin_user, user_role: 'super_admin') }

    it "clôt l'envoi sans rien transmettre au provider" do
      send_program_message!
      attempt = described_class.last

      attempt.archive!(admin_user: super_admin)

      expect(attempt.errors).to be_empty
      expect(attempt.reload.status).to eq('archived')
      expect(attempt.resolved_at).to be_present
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end

    it 'archive un envoi automatique, qui ne peut pas être relancé' do
      attempt = FactoryBot.create(:blocked_send_attempt, replay_params: {})

      attempt.archive!

      expect(attempt.reload.status).to eq('archived')
    end

    it "n'ajoute rien à la whitelist" do
      attempt = FactoryBot.create(:blocked_send_attempt)

      expect { attempt.archive! }.not_to change(AllowedPattern, :count)
    end

    it 'archive avec lui les tentatives sœurs du même envoi' do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'url')
      sibling = FactoryBot.create(:blocked_send_attempt, kind: 'keyword', detected_values: ['carte cadeau'])
      other = FactoryBot.create(:blocked_send_attempt, message_body: 'Autre message')

      attempt.archive!

      expect(sibling.reload.status).to eq('archived')
      expect(other.reload.status).to eq('pending')
    end

    %w[relaunched archived not_blocked].each do |status|
      it "refuse d'archiver une tentative #{status}" do
        attempt = FactoryBot.create(:blocked_send_attempt, status: status)

        attempt.archive!

        expect(attempt.errors.full_messages).to eq([described_class::ARCHIVE_REFUSED_MESSAGE])
        expect(attempt.reload.status).to eq(status)
      end
    end

    # Relance et archivage simultanés : la relance a réservé la tentative, le
    # message est peut-être déjà parti.
    it "refuse d'archiver une tentative réservée par une relance en cours" do
      attempt = FactoryBot.create(:blocked_send_attempt, force_send: true)

      attempt.archive!

      expect(attempt.errors.full_messages).to eq([described_class::ARCHIVE_REFUSED_MESSAGE])
      expect(attempt.reload.status).to eq('pending')
    end
  end

  describe 'relance et archivage simultanés' do
    it "refuse la relance d'une tentative archivée entre-temps" do
      send_program_message!
      attempt = described_class.last
      described_class.find(attempt.id).archive!

      attempt.relaunch!

      expect(attempt.errors.full_messages).to eq([described_class::RELAUNCH_REFUSED_MESSAGE])
      expect(attempt.reload.status).to eq('archived')
      expect(WebMock).not_to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs')
    end

    it "lève la réservation quand la relance échoue : l'envoi reste archivable" do
      send_program_message!
      attempt = described_class.last
      failing = instance_double(ProgramMessageService, errors: ['Aucun parent à contacter.'])
      allow(ProgramMessageService).to receive(:new).and_return(failing)
      allow(failing).to receive(:call).and_return(failing)

      attempt.relaunch!

      expect(attempt.reload).to have_attributes(status: 'pending', force_send: false)
      expect(attempt.archive!.errors).to be_empty
    end

    it "lève la réservation quand la relance plante : l'envoi reste relançable" do
      send_program_message!
      attempt = described_class.last
      allow(ProgramMessageService).to receive(:new).and_raise(ArgumentError, 'date invalide')

      expect { attempt.relaunch! }.to raise_error(ArgumentError)

      expect(attempt.reload).to have_attributes(status: 'pending', force_send: false)
    end
  end

  describe 'double relance' do
    it "n'envoie le message qu'une fois quand une relance est déjà en cours" do
      send_program_message!
      attempt = described_class.last
      second_click = described_class.find(attempt.id)
      replayer = BlockedSendAttempt::SendAttemptReplayer.new(attempt)
      allow(BlockedSendAttempt::SendAttemptReplayer).to receive(:new).and_return(replayer)
      allow(replayer).to receive(:call).and_wrap_original do |original|
        second_click.relaunch!
        original.call
      end

      attempt.relaunch!

      expect(replayer).to have_received(:call).once
      expect(second_click.errors.full_messages).to eq([described_class::RELAUNCH_IN_PROGRESS_MESSAGE])
      expect(attempt.reload.status).to eq('relaunched')
    end
  end

  describe 'clôture de la tâche de suivi' do
    let_it_be(:super_admin) { FactoryBot.create(:admin_user, user_role: 'super_admin') }
    let(:author) { FactoryBot.create(:admin_user, user_role: 'caller') }
    let(:attempt) { FactoryBot.create(:blocked_send_attempt, admin_user: author, replay_params: { recipients: ["parent.#{parent.id}"], message: message, provider: 'spothit', group_status: ['active'] }, message_body: message) }
    let!(:task) { BlockedSendAttempt::CreateTaskService.new(attempt: attempt).call.task }

    it 'clôt la tâche quand la relance aboutit, au nom du super_admin' do
      attempt.relaunch!(admin_user: super_admin)

      expect(task.reload).to have_attributes(status: 'done', treated_by: super_admin)
      expect(task.description).to include('Relancé le')
    end

    it 'laisse la tâche ouverte quand la relance échoue' do
      failing = instance_double(ProgramMessageService, errors: ['Aucun parent à contacter.'])
      allow(ProgramMessageService).to receive(:new).and_return(failing)
      allow(failing).to receive(:call).and_return(failing)

      attempt.relaunch!(admin_user: super_admin)

      expect(task.reload.done_at).to be_nil
    end

    it "clôt la tâche avec la mention « non relancé » à l'archivage" do
      attempt.archive!(admin_user: super_admin)

      expect(task.reload).to have_attributes(status: 'done', treated_by: super_admin)
      expect(task.description).to include("Non relancé : le message n'a pas été envoyé")
    end

    it "rapporte l'échec de la clôture sans annuler la relance" do
      errors = [{ message: "La tâche de l'envoi bloqué n'a pas pu être close", context: {} }]
      resolver = instance_double(BlockedSendAttempt::ResolveTaskService, errors: errors)
      allow(resolver).to receive(:call).and_return(resolver)
      allow(BlockedSendAttempt::ResolveTaskService).to receive(:new).and_return(resolver)
      allow(Rollbar).to receive(:error)

      attempt.relaunch!(admin_user: super_admin)

      expect(attempt.reload.status).to eq('relaunched')
      expect(Rollbar).to have_received(:error).with('BlockedSendAttempt::ResolveTaskService', errors: errors)
    end

    it 'relance quand même un envoi dont la tâche a été supprimée par un admin' do
      task.discard

      attempt.relaunch!(admin_user: super_admin)

      expect(attempt.reload.status).to eq('relaunched')
    end
  end

  # Depuis que l'atelier n'est plus créé quand son invitation est bloquée, seules
  # les tentatives tracées avant ce changement portent un workshop_id rejouable.
  describe "un admin technique relance une invitation d'atelier bloquée avant l'annulation des ateliers" do
    let_it_be(:animator) { FactoryBot.create(:admin_user, user_role: 'animator') }
    let(:invitation) do
      "Atelier parents bébés mardi à la PMI : lecture d'histoires, comptines et jeux. Pour toute information, contactez l'animatrice au 0612345678. " \
        'Pour vous inscrire ou dire que vous ne venez pas, cliquez sur ce lien: {RESPONSE_LINK}'
    end
    let(:workshop) do
      allow_any_instance_of(Workshop).to receive(:send_message)
      FactoryBot.create(:workshop, animator: animator, parents: [parent])
    end
    let(:attempt) do
      FactoryBot.create(
        :blocked_send_attempt,
        kind: 'phone_number',
        detected_values: ['0612345678'],
        message_body: invitation,
        replay_params: {
          planned_date: Time.zone.today.to_s,
          planned_hour: Time.zone.now.strftime('%H:%M'),
          recipients: ["parent.#{parent.id}"],
          message: invitation,
          rcs_media_id: nil,
          redirection_target_id: nil,
          quit_message: nil,
          workshop_id: workshop.id,
          supporter: nil,
          group_status: %w[waiting active paused stopped disengaged],
          provider: 'spothit',
          aircall_number_id: nil
        }
      )
    end

    it "transmet l'invitation avec le lien de réponse et met à jour les participants de l'atelier" do
      expect(workshop.workshop_participations).to be_empty

      service = attempt.relaunch!

      expect(service.errors).to be_empty
      expect(attempt.reload.status).to eq('relaunched')
      expect(workshop.workshop_participations.pluck(:related_id)).to eq([parent.id])
      expect(WebMock).to(have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/sms').with do |request|
        # Rejouée par le mauvais service, l'invitation partait avec un champ
        # `destinataires` vide : Spot-Hit répondait par son erreur 4.
        form = URI.decode_www_form(request.body).to_h
        form["destinataires[#{parent.phone_number}][RESPONSE_LINK]"].to_s.end_with?("/#{parent.security_token}/#{workshop.id}")
      end)
    end
  end
end
