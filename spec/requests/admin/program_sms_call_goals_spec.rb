require 'rails_helper'

RSpec.describe 'Petite mission enregistrée par le formulaire Message', type: :request do
  let!(:camille) { FactoryBot.create(:admin_user, user_role: 'caller', name: 'Camille') }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) do
    FactoryBot.create(:child, parent1: parent, should_contact_parent1: true, group: FactoryBot.create(:group), group_status: 'active')
  end
  let(:child_support) { child.child_support }

  before do
    child_support.update!(supporter: camille)
    sign_in camille
  end

  def program_sms(template:, message:, call_goal: nil)
    post '/admin/message/program_sms',
         params: {
           planned_date: Time.zone.today.to_s,
           planned_hour: Time.zone.now.strftime('%H:%M'),
           recipients: ["parent.#{parent.id}"],
           group_status: ['active'],
           parent_id: parent.id,
           call_goals_sms: template,
           call_goal: call_goal,
           message: message
         },
         headers: { 'HTTP_REFERER' => '/admin/tasks' }
  end

  context 'avec un message sans contenu suspect' do
    it 'écrit la petite mission dès l’envoi' do
      program_sms(template: 'call2_goals', message: 'Voici votre petite mission : lire une histoire')

      expect(child_support.reload.call2_goals_sms).to eq('Voici votre petite mission : lire une histoire')
      expect(BlockedSendAttempt.count).to eq(0)
      expect(flash[:notice]).to eq('Message(s) programmé(s) via Spothit. Et petite mission définie')
    end

    it "retient la mission de l'appel 0 pour le rappel" do
      program_sms(template: 'call0_goals', message: 'Voici votre petite mission : chanter', call_goal: 'Chanter une comptine au bain')

      expect(child_support.reload).to have_attributes(call0_goals_sms: 'Voici votre petite mission : chanter', call0_goal_sent: 'Chanter une comptine au bain')
    end

    it 'n’écrit aucune petite mission avec le modèle « Aucun »' do
      program_sms(template: 'Aucun', message: 'Bonjour')

      expect(child_support.reload.attributes.values_at('call0_goals_sms', 'call1_goals_sms', 'call2_goals_sms', 'call3_goals_sms')).to all(be_blank)
      expect(flash[:notice]).to eq('Message(s) programmé(s) via Spothit')
    end
  end

  context 'quand le blocage de contenu bloque l’envoi' do
    let(:blocked_message) { 'Voici votre petite mission https://exemple-non-autorise.fr' }

    around do |example|
      previous = ENV.fetch('URL_FILTER_BLOCKING_ENABLED', nil)
      ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
      example.run
      ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
    end

    it 'n’écrit pas la petite mission et affiche l’alerte de blocage' do
      program_sms(template: 'call1_goals', message: blocked_message)

      expect(child_support.reload.call1_goals_sms).to be_blank
      expect(BlockedSendAttempt.last).to have_attributes(status: 'pending')
      expect(flash[:alert]).to include(BlockedSendAttempt::SendGuard::BLOCKED_MESSAGE)
    end

    it 'mémorise dans la tentative la fiche et le modèle de la petite mission' do
      program_sms(template: 'call3_goals_observing', message: blocked_message, call_goal: 'Observer le bain')

      expect(BlockedSendAttempt.last.replay_params['call_goals']).to eq(
        'child_support_id' => child_support.id,
        'template' => 'call3_goals_observing'
      )
    end

    it "mémorise aussi la mission pour l'appel 0" do
      program_sms(template: 'call0_goals', message: blocked_message, call_goal: 'Chanter une comptine au bain')

      expect(BlockedSendAttempt.last.replay_params['call_goals']).to eq(
        'child_support_id' => child_support.id,
        'template' => 'call0_goals',
        'call_goal' => 'Chanter une comptine au bain'
      )
      expect(child_support.reload.call0_goal_sent).to be_blank
    end

    it 'ne mémorise rien avec le modèle « Aucun »' do
      program_sms(template: 'Aucun', message: blocked_message)

      expect(BlockedSendAttempt.last.replay_params).not_to have_key('call_goals')
    end
  end

  context 'en mode surveillance' do
    around do |example|
      previous = ENV.fetch('URL_FILTER_BLOCKING_ENABLED', nil)
      ENV.delete('URL_FILTER_BLOCKING_ENABLED')
      example.run
      ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
    end

    it 'écrit la petite mission et trace la tentative sans bloquer' do
      program_sms(template: 'call1_goals', message: 'Voici votre petite mission https://exemple-non-autorise.fr')

      expect(child_support.reload.call1_goals_sms).to eq('Voici votre petite mission https://exemple-non-autorise.fr')
      expect(BlockedSendAttempt.last).to have_attributes(status: 'not_blocked')
    end
  end
end
