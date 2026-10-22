require 'rails_helper'

RSpec.describe 'Admin — Mes statistiques d’appel', type: :request do
  let(:path) { '/admin/mes_statistiques_d_appel' }
  let(:secret_key) { 'clef-de-test' }
  let(:configuration) do
    { 'METABASE_URL' => 'https://metabase.example.org', 'METABASE_SECRET_KEY' => secret_key, 'METABASE_DASHBOARD_ID' => '112' }
  end
  let(:unavailable_message) { 'Les statistiques ne sont pas disponibles pour le moment.' }

  def stub_metabase_configuration(values)
    stub_const('ENV', ENV.to_h.except(*configuration.keys).merge(values))
  end

  def iframe
    Nokogiri::HTML(response.body).at_css('iframe')
  end

  def decoded_payload(key = secret_key)
    token = iframe['src'][%r{/embed/dashboard/([^#]+)#}, 1]
    JWT.decode(token, key, true, algorithm: 'HS256').first
  end

  before { stub_metabase_configuration(configuration) }

  configurations_incompletes = {
    'entièrement absente' => %w[METABASE_URL METABASE_SECRET_KEY METABASE_DASHBOARD_ID],
    'sans la clef de signature' => %w[METABASE_SECRET_KEY],
    'sans l’id du dashboard' => %w[METABASE_DASHBOARD_ID],
    'sans l’adresse du site Metabase' => %w[METABASE_URL]
  }

  %w[caller animator].each do |role|
    describe "pour un #{role}" do
      let(:admin_user) { FactoryBot.create(:admin_user, user_role: role) }

      before { sign_in admin_user }

      context 'avec la configuration Metabase' do
        before { get path }

        it 'affiche la page avec son titre' do
          expect(response).to have_http_status(:ok)
          expect(Nokogiri::HTML(response.body).at_css('#page_title').text).to eq("Mes statistiques d'appel")
        end

        it 'affiche l’iframe du dashboard' do
          expect(iframe['src']).to start_with('https://metabase.example.org/embed/dashboard/')
          expect(iframe['src']).to end_with('#bordered=true&titled=true')
        end

        it 'signe un jeton avec la clef, pour le dashboard 112 et sans paramètre' do
          payload = decoded_payload

          expect(payload['resource']).to eq('dashboard' => 112)
          expect(payload['params']).to eq({})
        end

        it 'ne montre pas le message d’indisponibilité' do
          expect(response.body).not_to include(unavailable_message)
        end

        it 'ne laisse pas la clef apparaître dans la page' do
          expect(response.body).not_to include(secret_key)
        end
      end

      it 'fait expirer le jeton 10 minutes après l’ouverture de la page' do
        freeze_time do
          get path

          expect(decoded_payload['exp']).to eq(10.minutes.from_now.to_i)
        end
      end

      it 'ignore un paramètre d’URL forgé' do
        get path, params: { dashboard: 999, dashboard_id: 999, params: { id: 1 } }

        payload = decoded_payload
        expect(payload['resource']).to eq('dashboard' => 112)
        expect(payload['params']).to eq({})
      end

      configurations_incompletes.each do |etat, absentes|
        context "quand la configuration est #{etat}" do
          before do
            stub_metabase_configuration(configuration.except(*absentes))
            allow(JWT).to receive(:encode).and_call_original
            get path
          end

          it 'affiche le titre et le message d’indisponibilité, sans iframe' do
            expect(response).to have_http_status(:ok)
            expect(Nokogiri::HTML(response.body).at_css('#page_title').text).to eq("Mes statistiques d'appel")
            expect(response.body).to include(unavailable_message)
            expect(iframe).to be_nil
          end

          it 'ne génère aucun jeton' do
            expect(JWT).not_to have_received(:encode)
          end
        end
      end
    end
  end

  it 'donne le même dashboard à deux accompagnantes, sans paramètre' do
    awa = FactoryBot.create(:admin_user, user_role: 'caller')
    bintou = FactoryBot.create(:admin_user, user_role: 'animator')

    payloads = [awa, bintou].map do |user|
      sign_in user
      get path
      sign_out user
      decoded_payload
    end

    expect(payloads.pluck('resource')).to all(eq('dashboard' => 112))
    expect(payloads.pluck('params')).to all(eq({}))
  end

  %w[super_admin contributor reader].each do |role|
    describe "pour un #{role}" do
      before do
        allow(JWT).to receive(:encode).and_call_original
        sign_in FactoryBot.create(:admin_user, user_role: role)
        get path
      end

      it 'redirige vers la liste des enfants avec un message d’accès refusé' do
        expect(response).to redirect_to(admin_children_url)
        expect(flash[:alert]).to be_present
      end

      it 'ne génère aucun jeton' do
        expect(JWT).not_to have_received(:encode)
      end
    end
  end

  it 'renvoie un visiteur non connecté vers la connexion' do
    get path

    expect(response).to redirect_to('/admin/login')
  end

  %w[caller animator].each do |role|
    it "n'affiche rien à un #{role} dont le compte est désactivé" do
      allow(JWT).to receive(:encode).and_call_original
      sign_in FactoryBot.create(:admin_user, user_role: role, is_disabled: true)

      get path

      expect(response).to redirect_to('/admin/login')
      expect(JWT).not_to have_received(:encode)
    end
  end
end
