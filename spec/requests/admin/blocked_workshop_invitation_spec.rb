require 'rails_helper'

RSpec.describe "Création d'un atelier dont l'invitation est bloquée", type: :request do
  let(:animator) { FactoryBot.create(:admin_user, user_role: 'animator', name: 'Marc') }
  let(:invitation_message) { 'Inscrivez-vous : https://exemple-non-autorise.fr' }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) do
    FactoryBot.create(:child, parent1: parent, should_contact_parent1: true, group: FactoryBot.create(:group), group_status: 'active')
  end

  # DEFAULT_HOSTNAME, comme en production : les liens de réponse à l'atelier
  # (domaine de l'app) sont autorisés et seul le lien saisi est détecté.
  around do |example|
    previous = ENV.to_h.slice('URL_FILTER_BLOCKING_ENABLED', 'DEFAULT_HOSTNAME')
    ENV['URL_FILTER_BLOCKING_ENABLED'] = 'true'
    ENV['DEFAULT_HOSTNAME'] = 'localhost'
    example.run
    %w[URL_FILTER_BLOCKING_ENABLED DEFAULT_HOSTNAME].each { |key| previous.key?(key) ? ENV[key] = previous[key] : ENV.delete(key) }
  end

  before do
    FactoryBot.create(:admin_user, user_role: 'super_admin', email: ENV.fetch('BLOCKED_SEND_ASSIGNEE_EMAIL'))
    sign_in animator
  end

  def create_workshop
    post '/admin/workshops', params: {
      workshop: {
        workshop_date: 3.weeks.from_now.to_date.to_s,
        first_workshop_time_slot: '11:00',
        animator_id: animator.id,
        address: '12 rue de la Paix',
        postal_code: '75020',
        city_name: 'Paris',
        location: 'Mediatheque',
        invitation_message: invitation_message,
        workshop_land: 'Paris 20 eme',
        parent_ids: parent.id.to_s
      }
    }
  end

  it "ne crée pas l'atelier et ré-affiche le formulaire avec le message de blocage" do
    expect { create_workshop }.not_to change(Workshop, :count)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(ERB::Util.html_escape(BlockedSendAttempt::SendGuard::BLOCKED_MESSAGE))
    expect(response.body).to include(invitation_message)
    expect(response.body).not_to include('Aucune invitation n&#39;a pu être envoyée')
  end

  it "crée la tâche de Marc et la tentative, qu'un super_admin peut seulement archiver" do
    expect { create_workshop }.to change(Task, :count).by(1).and change(BlockedSendAttempt.pending, :count).by(1)

    expect(Task.last.reporter).to eq(animator)
    sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')
    get "/admin/blocked_send_attempts/#{BlockedSendAttempt.last.id}"

    expect(response.body).to include('Archiver sans envoyer')
    expect(response.body).not_to include('Relancer cet envoi')
  end
end
