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
#
# Indexes
#
#  index_blocked_send_attempts_on_status  (status)
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

  describe 'un BlockedSendAttempt déjà relancé peut être relancé une seconde fois (aucune garde)' do
    it 'retransmet le message une seconde fois au destinataire d\'origine sans garde anti-doublon' do
      FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'exact', value: blocked_url)
      attempt = FactoryBot.create(
        :blocked_send_attempt,
        provider: 'spothit',
        status: 'relaunched',
        resolved_at: Time.zone.now,
        replay_params: {
          planned_date: Time.zone.today.to_s,
          planned_hour: Time.zone.now.strftime('%H:%M'),
          recipients: ["parent.#{parent.id}"],
          message: message,
          rcs_media_id: nil,
          redirection_target_id: nil,
          quit_message: false,
          workshop_id: nil,
          supporter: nil,
          group_status: ['active'],
          provider: 'spothit',
          aircall_number_id: nil
        }
      )

      attempt.relaunch!

      expect(attempt.reload.status).to eq('relaunched')
      expect(WebMock).to have_requested(:post, 'https://www.spot-hit.fr/api/envoyer/rcs').once
    end
  end
end
