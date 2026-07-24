require 'rails_helper'

RSpec.describe 'Admin child support - création de RDV par l’accompagnante', type: :request do
  let(:supporter_email) { 'beta.caller@1001mots.org' }
  let(:supporter) do
    FactoryBot.create(:admin_user,
      user_role: 'caller',
      email: supporter_email,
      can_send_automatic_sms: true,
      calendly_user_uri: 'https://api.calendly.com/users/abc123',
      aircall_phone_number: '+33123456789'
    )
  end
  let!(:group) { FactoryBot.create(:group, started_at: Date.current.beginning_of_week(:monday)) }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) { FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active') }
  let!(:child_support) { child.child_support.tap { |cs| cs.update!(supporter: supporter) } }

  let(:booking_url) { 'https://calendly.com/d/one-off-xyz789' }
  let(:one_off_response) do
    { 'resource' => { 'booking_url' => booking_url } }
  end

  let(:action_path) do
    "/admin/child_supports/#{child_support.id}/create_scheduled_call?parent_id=#{parent.id}"
  end

  before do
    stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => supporter_email))
    stub_request(:post, 'https://api.calendly.com/one_off_event_types')
      .to_return(status: 201, body: one_off_response.to_json, headers: { 'Content-Type' => 'application/json' })
    sign_in supporter
  end

  describe 'affichage de la zone RDV sur la fiche de suivi' do
    let(:edit_path) { "/admin/child_supports/#{child_support.id}/edit?r=true" }

    it 'affiche le bouton Créer un rdv quand le supporter est éligible' do
      get edit_path
      expect(response.body).to include('Créer un rdv')
      expect(response.body).not_to include('La prise des rdv n&#39;est pas activée')
    end

    context 'quand la fiche a deux parents contactables' do
      let!(:parent2) { FactoryBot.create(:parent) }

      before { child.update!(parent2: parent2, should_contact_parent2: true) }

      it 'demande un choix explicite entre les deux parents' do
        get edit_path
        expect(response.body).to include('(Parent 1)')
        expect(response.body).to include('(Parent 2)')
        expect(response.body).to include("create_scheduled_call?parent_id=#{parent.id}")
        expect(response.body).to include("create_scheduled_call?parent_id=#{parent2.id}")
      end
    end
  end

  context 'quand aucun RDV actif n’existe et qu’un lien est en cache' do
    let(:cached_url) { 'https://calendly.com/d/cached-link?utm_campaign=call0' }

    before do
      parent.update!(calendly_booking_urls: { 'call0' => cached_url })
    end

    it 'réutilise le lien existant sans appel à l’API Calendly' do
      get action_path
      expect(response.headers['Location']).to start_with('https://calendly.com/d/cached-link')
      expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
    end

    it 'ajoute le préremplissage du parent au lien en cache' do
      get action_path
      params = URI.decode_www_form(URI.parse(response.headers['Location']).query).to_h
      expect(params['utm_campaign']).to eq('call0')
      expect(params['name']).to eq("#{parent.first_name} #{parent.last_name}")
      expect(params['first_name']).to eq(parent.first_name)
      expect(params['last_name']).to eq(parent.last_name)
    end
  end

  context 'quand aucun lien n’est en cache' do
    it 'génère un one-off event type ciblant ce parent et redirige vers le lien' do
      get action_path
      expect(WebMock).to have_requested(:post, 'https://api.calendly.com/one_off_event_types').once
      expect(response.headers['Location']).to include(booking_url)
      expect(response.headers['Location']).to include("utm_content=#{parent.security_token}")
    end
  end

  context 'quand un RDV actif existe déjà pour la session' do
    before do
      parent.update!(calendly_booking_urls: { 'call0' => 'https://calendly.com/d/cached-link' })
      FactoryBot.create(:scheduled_call,
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/existing',
        status: 'scheduled',
        call_session: 0,
        child_support: child_support,
        parent: parent,
        scheduled_at: 2.days.from_now
      )
    end

    it 'génère un nouveau lien malgré le lien en cache' do
      get action_path
      expect(WebMock).to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
        .with(body: hash_including('duration' => 30)).once
      expect(response.headers['Location']).to include(booking_url)
    end
  end

  context 'quand aucune session n’est active mais qu’une session future existe' do
    let!(:group) { FactoryBot.create(:group, started_at: 10.days.from_now.to_date.next_occurring(:monday)) }

    it 'génère un lien pour la session future avec les dates de la cohorte' do
      get action_path
      expect(WebMock).to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
        .with(body: hash_including(
          'date_setting' => {
            'type' => 'date_range',
            'start_date' => group.call0_start_date.to_s,
            'end_date' => group.call0_end_date.to_s
          }
        ))
      expect(response.headers['Location']).to include(booking_url)
    end
  end

  context 'quand le supporter a can_send_automatic_sms = false' do
    before { supporter.update!(can_send_automatic_sms: false) }

    it 'refuse avec le message de fonctionnalité désactivée' do
      get action_path
      expect(response).to redirect_to(edit_admin_child_support_path(child_support))
      expect(flash[:alert]).to eq("La prise des rdv n'est pas activée")
    end
  end

  context 'quand le supporter n’est pas dans la liste bêta' do
    before do
      stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => 'other@1001mots.org'))
    end

    it 'refuse avec le message de fonctionnalité désactivée' do
      get action_path
      expect(response).to redirect_to(edit_admin_child_support_path(child_support))
      expect(flash[:alert]).to eq("La prise des rdv n'est pas activée")
    end
  end

  context 'quand le parent est à ne pas contacter' do
    before { child.update!(should_contact_parent1: false) }

    it 'refuse la création' do
      get action_path
      expect(flash[:alert]).to eq('Ce parent est à ne pas contacter')
      expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
    end
  end

  context 'quand l’API Calendly renvoie une erreur' do
    let!(:existing_scheduled_call) do
      FactoryBot.create(:scheduled_call,
        calendly_event_uri: 'https://api.calendly.com/scheduled_events/existing',
        status: 'scheduled',
        call_session: 0,
        child_support: child_support,
        parent: parent,
        scheduled_at: 2.days.from_now
      )
    end

    before do
      stub_request(:post, 'https://api.calendly.com/one_off_event_types')
        .to_return(status: 400, body: { 'message' => 'Invalid request' }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'envoie l’erreur à Rollbar sans le corps de la réponse Calendly' do
      expect(Rollbar).to receive(:error) do |_message, details|
        expect(details[:child_support_id]).to eq(child_support.id)
        expect(details[:errors]).to all(satisfy { |e| !e.is_a?(Hash) || !e.key?(:error) })
      end
      get action_path
    end

    it 'affiche un message d’erreur générique' do
      get action_path
      expect(flash[:alert]).to eq('La génération du lien de RDV a échoué, veuillez réessayer plus tard')
    end

    it 'ne modifie aucun ScheduledCall' do
      allow(Rollbar).to receive(:error)
      get action_path
      expect(existing_scheduled_call.reload.status).to eq('scheduled')
    end
  end

  context 'quand l’accompagnante n’est pas celle de la fiche de suivi' do
    let(:other_caller) do
      FactoryBot.create(:admin_user, user_role: 'caller', can_send_automatic_sms: true)
    end

    before { sign_in other_caller }

    it 'refuse l’accès' do
      get action_path
      expect(response).not_to redirect_to(booking_url)
      expect(WebMock).not_to have_requested(:post, 'https://api.calendly.com/one_off_event_types')
    end
  end
end
