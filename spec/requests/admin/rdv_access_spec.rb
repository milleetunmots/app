require 'rails_helper'

RSpec.describe 'Admin - accès à la prise de RDV sans liste bêta', type: :request do
  let(:awa) { FactoryBot.create(:admin_user, user_role: 'caller', email: 'awa@1001mots.org', can_send_automatic_sms: true) }
  let(:bintou) { FactoryBot.create(:admin_user, user_role: 'caller', email: 'bintou@1001mots.org', can_send_automatic_sms: false) }

  # BETA_TEST_CALLERS_EMAIL n'est plus lue : la variable est absente ici.
  before { stub_const('ENV', ENV.to_h.except('BETA_TEST_CALLERS_EMAIL')) }

  def utility_nav_links
    Nokogiri::HTML(response.body).css('#utility_nav a').pluck('href')
  end

  %w[caller animator].each do |role|
    context "quand un #{role} hors liste bêta ouvre son tableau de bord" do
      let(:admin_user) { FactoryBot.create(:admin_user, user_role: role, can_send_automatic_sms: true) }

      before do
        sign_in admin_user
        get '/admin/dashboard'
      end

      it "affiche l'encart des paramètres de rendez-vous" do
        expect(response.body).to include('Paramètres des rendez-vous')
        expect(response.body).to include('Accéder aux réglages')
      end

      it 'affiche le menu RDV Calendly' do
        expect(response.body).to include('RDV Calendly')
      end

      it 'propose la page Réglages de RDV dans le menu de son avatar' do
        expect(utility_nav_links).to include('/admin/reglages_de_rdv')
      end
    end
  end

  context "quand l'envoi automatique est désactivé" do
    before { sign_in bintou }

    it "affiche quand même l'encart, le menu et le lien des réglages dans l'avatar" do
      get '/admin/dashboard'

      expect(response.body).to include('Paramètres des rendez-vous')
      expect(response.body).to include('RDV Calendly')
      expect(utility_nav_links).to include('/admin/reglages_de_rdv')
    end

    it 'propose de réactiver les SMS de RDV depuis la page Réglages' do
      get '/admin/reglages_de_rdv'

      expect(response.body).to include('Activer les SMS de RDV')
    end

    it "réactive l'envoi et enregistre l'instant de réactivation" do
      post '/admin/reglages_de_rdv/toggle_automatic_sms'

      expect(bintou.reload.can_send_automatic_sms).to be(true)
      expect(bintou.automatic_sms_activated_at).to be_present
    end
  end

  %w[super_admin contributor reader].each do |role|
    context "quand un #{role} ouvre son tableau de bord" do
      before do
        sign_in FactoryBot.create(:admin_user, user_role: role)
        get '/admin/dashboard'
      end

      it 'voit le menu RDV Calendly' do
        expect(response.body).to include('RDV Calendly')
      end

      it "ne voit pas l'encart réservé aux accompagnantes" do
        expect(response.body).not_to include('Paramètres des rendez-vous')
      end
    end
  end

  describe 'filtre des accompagnantes sans envoi automatique' do
    let!(:silent_supporter) { FactoryBot.create(:admin_user, user_role: 'caller', can_send_automatic_sms: false, name: 'Bintou Silencieuse') }
    let!(:active_supporter) { FactoryBot.create(:admin_user, user_role: 'caller', can_send_automatic_sms: true, name: 'Awa Active') }

    before do
      FactoryBot.create(:child).child_support.update!(supporter: silent_supporter)
      FactoryBot.create(:child).child_support.update!(supporter: active_supporter)
      sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')
    end

    it 'affiche le filtre libellé sans notion de bêta et liste les accompagnantes désactivées' do
      get '/admin/admin_users', params: { scope: 'supporters_who_cannot_send_automatic_sms' }

      expect(response.body).to include('Accompagnantes sans envoi automatique')
      expect(response.body).not_to include('Beta testeuses')
      expect(response.body).to include(silent_supporter.email)
      expect(response.body).not_to include(active_supporter.email)
    end
  end

  describe 'liste et fiche des RDV Calendly' do
    let!(:awa_call) { FactoryBot.create(:scheduled_call, :with_child_support, :with_parent, admin_user: awa) }
    let!(:bintou_call) { FactoryBot.create(:scheduled_call, :with_child_support, :with_parent, admin_user: bintou) }

    before { sign_in awa }

    it 'ne liste que ses propres RDV' do
      get '/admin/scheduled_calls'

      expect(response.body).to include("/admin/scheduled_calls/#{awa_call.id}")
      expect(response.body).not_to include("/admin/scheduled_calls/#{bintou_call.id}")
    end

    it "rend le RDV d'une autre accompagnante introuvable (404 en production)" do
      expect { get "/admin/scheduled_calls/#{bintou_call.id}" }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
