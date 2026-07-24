# == Schema Information
#
# Table name: blocked_send_attempts
#
#  id              :bigint           not null, primary key
#  detected_values :string           default([]), not null, is an Array
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

  describe "un admin technique tente de relancer alors que l'URL n'est toujours pas whitelistée" do
    it 'rebloque le message par le même contrôle, reste pending et ne crée pas de doublon' do
      send_program_message!
      attempt = BlockedSendAttempt.last

      expect { attempt.relaunch! }.not_to change(BlockedSendAttempt, :count)
      expect(attempt.reload.status).to eq('pending')
      expect(attempt.resolved_at).to be_nil
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
