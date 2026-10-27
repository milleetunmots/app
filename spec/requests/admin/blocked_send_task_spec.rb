require 'rails_helper'

RSpec.describe 'Tâche de suivi d’un envoi bloqué', type: :request do
  let!(:assignee) { FactoryBot.create(:admin_user, user_role: 'super_admin', email: ENV.fetch('BLOCKED_SEND_ASSIGNEE_EMAIL')) }
  let!(:awa) { FactoryBot.create(:admin_user, user_role: 'caller', name: 'Awa') }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) do
    FactoryBot.create(:child, parent1: parent, should_contact_parent1: true, group: FactoryBot.create(:group), group_status: 'active')
  end
  let(:blocked_message) { 'Rejoignez-nous sur https://exemple-non-autorise.fr' }

  around do |example|
    previous = ENV.fetch('URL_FILTER_BLOCKING_ENABLED', nil)
    ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
    example.run
    ENV['URL_FILTER_BLOCKING_ENABLED'] = previous
  end

  before do
    child.child_support.update!(supporter: awa)
    sign_in awa
  end

  def program_sms
    post '/admin/message/program_sms',
         params: {
           planned_date: Time.zone.today.to_s,
           planned_hour: Time.zone.now.strftime('%H:%M'),
           recipients: ["parent.#{parent.id}"],
           group_status: ['active'],
           message: blocked_message
         },
         headers: { 'HTTP_REFERER' => '/admin/tasks' }
  end

  it "n'envoie rien, crée la tâche d'Awa et lui affiche le lien vers cette tâche" do
    expect { program_sms }.to change(Task, :count).by(1)

    task = Task.last
    expect(task).to have_attributes(reporter: awa, assignee: assignee, related: BlockedSendAttempt.last)
    expect(BlockedSendAttempt.last).to have_attributes(status: 'pending', admin_user: awa)
    expect(WebMock).not_to have_requested(:post, %r{https://www\.spot-hit\.fr})

    follow_redirect!
    task_url = "http://localhost:3000/admin/tasks/#{task.id}"
    expect(response.body).to include(ERB::Util.html_escape(BlockedSendAttempt::SendGuard::BLOCKED_MESSAGE))
    expect(response.body).to include(%(<a href="#{task_url}">#{task_url}</a>))
  end

  it "liste la tâche dans les tâches d'Awa" do
    program_sms

    get '/admin/tasks'

    expect(response.body).to include('Envoi bloqué à vérifier')
  end

  it "ouvre la tâche pour Awa avec son message, sans lien vers la tentative qu'elle ne peut pas lire" do
    program_sms

    get "/admin/tasks/#{Task.last.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(blocked_message)
    expect(response.body).to include("Envoi bloqué n°#{BlockedSendAttempt.last.id}")
    expect(response.body).not_to include("/admin/blocked_send_attempts/#{BlockedSendAttempt.last.id}")
  end

  it 'affiche la tâche dans le tableau de bord du compte assigné' do
    program_sms
    sign_in assignee

    get '/admin/dashboard'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Envoi bloqué à vérifier')
  end
end
