require 'rails_helper'

RSpec.describe "Petite mission d'un envoi bloqué puis relancé", type: :request do
  let!(:marion) { FactoryBot.create(:admin_user, user_role: 'super_admin', name: 'Marion', email: ENV.fetch('BLOCKED_SEND_ASSIGNEE_EMAIL')) }
  let!(:camille) { FactoryBot.create(:admin_user, user_role: 'caller', name: 'Camille', aircall_number_id: 42) }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) do
    FactoryBot.create(:child, parent1: parent, should_contact_parent1: true, group: FactoryBot.create(:group), group_status: 'active')
  end
  let(:child_support) { child.child_support }
  let(:blocked_message) { 'Voici votre petite mission https://exemple-non-autorise.fr' }
  let(:today) { Time.zone.today.strftime('%d/%m/%Y') }

  around do |example|
    previous = ENV.fetch('URL_FILTER_BLOCKING_ENABLED', nil)
    ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
    example.run
    ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
  end

  before { child_support.update!(supporter: camille) }

  def program_sms(template:, provider: 'spothit', call_goal: nil)
    sign_in camille
    post '/admin/message/program_sms',
         params: {
           planned_date: Time.zone.today.to_s,
           planned_hour: Time.zone.now.strftime('%H:%M'),
           recipients: ["parent.#{parent.id}"],
           group_status: ['active'],
           parent_id: parent.id,
           provider: provider,
           call_goals_sms: template,
           call_goal: call_goal,
           message: blocked_message
         },
         headers: { 'HTTP_REFERER' => '/admin/tasks' }
    sign_out camille
  end

  def relaunch
    sign_in marion
    put "/admin/blocked_send_attempts/#{BlockedSendAttempt.last.id}/relaunch"
  end

  it 'écrit la petite mission dans la fiche et clôt la tâche de Camille' do
    program_sms(template: 'call1_goals')
    expect(child_support.reload.call1_goals_sms).to be_blank

    relaunch

    expect(BlockedSendAttempt.last.status).to eq('relaunched')
    expect(child_support.reload.call1_goals_sms).to eq(blocked_message)
    task = Task.find_by(related: BlockedSendAttempt.last)
    expect(task).to have_attributes(status: 'done', reporter: camille)
    expect(task.description).to end_with("Relancé le #{today} : le message a été envoyé.")
  end

  it 'laisse en place la petite mission déjà présente et prévient Camille dans sa tâche' do
    program_sms(template: 'call1_goals')
    child_support.update!(call1_goals_sms: 'PM reformulée')

    relaunch

    expect(child_support.reload.call1_goals_sms).to eq('PM reformulée')
    expect(Task.find_by(related: BlockedSendAttempt.last).description).to end_with(
      "Relancé le #{today} : le message a été envoyé.<br><br>#{BlockedSendAttempt::ResolveTaskService::CALL_GOALS_NOT_SAVED_LINE}"
    )
  end

  context 'via Aircall' do
    around do |example|
      previous_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
      ActiveJob::Base.queue_adapter = previous_adapter
    end

    it "programme l'envoi Aircall et écrit la petite mission de l'appel 0" do
      program_sms(template: 'call0_goals', provider: 'aircall', call_goal: 'Chanter une comptine au bain')
      expect(BlockedSendAttempt.last.provider).to eq('aircall')
      expect(Aircall::SendMessageJob).not_to have_been_enqueued

      relaunch

      expect(Aircall::SendMessageJob).to have_been_enqueued.with(42, parent.phone_number, blocked_message, any_args)
      expect(child_support.reload).to have_attributes(call0_goals_sms: blocked_message, call0_goal_sent: 'Chanter une comptine au bain')
    end
  end
end
