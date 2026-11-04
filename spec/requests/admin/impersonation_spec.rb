require 'rails_helper'

RSpec.describe 'Admin - se connecter en tant que', type: :request do
  let(:super_admin) { FactoryBot.create(:admin_user, user_role: 'super_admin') }
  let(:referente) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:texte_sensible) { 'Père placé en foyer' }
  let!(:fiche) do
    FactoryBot.create(:child_support, supporter: referente, parent_needs: 'Avant').tap do |child_support|
      child_support.update!(sensitive_information: texte_sensible)
    end
  end
  let!(:fiche_d_une_autre) { FactoryBot.create(:child_support, supporter: FactoryBot.create(:admin_user, user_role: 'caller')) }

  def start_impersonating(admin_user)
    post "/admin/impersonation/#{admin_user.id}"
  end

  describe 'démarrage' do
    it 'est proposé sur la page du compte' do
      sign_in super_admin
      get "/admin/admin_users/#{referente.id}"

      expect(response.body).to include('Se connecter en tant que')
    end

    it "ouvre l'admin avec le périmètre du compte simulé, sans second facteur pour lui" do
      sign_in super_admin
      start_impersonating(referente)

      expect(response).to redirect_to(admin_root_path)
      get '/admin/child_supports', params: { scope: 'all' }
      expect(response.body).to include('impersonation-banner')
      expect(response.body).to include(%(id="child_support_#{fiche.id}"))
      expect(response.body).not_to include(%(id="child_support_#{fiche_d_une_autre.id}"))
    end

    it 'est refusée pour un autre super admin' do
      sign_in super_admin
      start_impersonating(FactoryBot.create(:admin_user, user_role: 'super_admin'))

      expect(flash[:alert]).to include('Vous ne pouvez pas')
      expect(session[:impersonated_admin_user_id]).to be_nil
    end

    it 'est refusée pour un compte désactivé' do
      referente.update_column(:is_disabled, true)
      sign_in super_admin
      start_impersonating(referente)

      expect(session[:impersonated_admin_user_id]).to be_nil
    end

    %w[contributor reader caller animator].each do |role|
      it "est refusée à un #{role}" do
        sign_in FactoryBot.create(:admin_user, user_role: role)
        start_impersonating(referente)

        expect(session[:impersonated_admin_user_id]).to be_nil
      end
    end
  end

  describe 'lecture seule' do
    before do
      sign_in super_admin
      start_impersonating(referente)
    end

    it 'affiche le formulaire de la fiche de suivi' do
      get "/admin/child_supports/#{fiche.id}/edit", params: { r: 'true' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('impersonating')
    end

    it "refuse l'enregistrement de la fiche" do
      patch "/admin/child_supports/#{fiche.id}", params: { child_support: { parent_needs: 'Après' } }

      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to include('Lecture seule')
      expect(fiche.reload.parent_needs).to eq('Avant')
    end

    it 'répond 403 en JSON à un enregistrement AJAX' do
      patch "/admin/child_supports/#{fiche.id}", params: { child_support: { parent_needs: 'Après' } }, xhr: true

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to include('impersonation' => true)
      expect(fiche.reload.parent_needs).to eq('Avant')
    end

    it 'refuse les écritures hors ActiveAdmin' do
      fiche.update_column(:address_suspected_invalid_at, Time.current)
      post "/child-support-address-valid/#{fiche.id}", xhr: true

      expect(response).to have_http_status(:forbidden)
      expect(fiche.reload.address_suspected_invalid_at).to be_present
    end

    it "laisse ouvrir la page Message mais refuse l'envoi" do
      get '/admin/message'
      expect(response).to have_http_status(:ok)

      expect(ProgramMessageService).not_to receive(:new)
      post '/admin/message/program_sms', params: { message: 'Bonjour', recipients: ["parent.#{fiche.parent1.id}"] }

      expect(flash[:alert]).to include('Lecture seule')
    end

    it 'refuse les page_action en POST' do
      post '/admin/reglages_de_rdv/toggle_automatic_sms'

      expect(flash[:alert]).to include('Lecture seule')
    end
  end

  describe 'actions ActiveAdmin en GET à effet de bord' do
    let(:contributrice) { FactoryBot.create(:admin_user, user_role: 'contributor') }
    let(:group) { FactoryBot.create(:group) }

    before do
      sign_in super_admin
      start_impersonating(contributrice)
    end

    it 'refuse la programmation d’une cohorte' do
      expect(Group::ProgramService).not_to receive(:new)

      get "/admin/groups/#{group.id}/program"

      expect(flash[:alert]).to include('Lecture seule')
    end

    it 'refuse une collection_action sans contrôle de droits' do
      expect(Video::ImportFromAirtableService).not_to receive(:new)

      get '/admin/media_videos/import_from_airtable'

      expect(flash[:alert]).to include('Lecture seule')
    end

    it 'laisse consulter la cohorte' do
      # L'onglet des envois programmés lit Sidekiq : pas de Redis en CI
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return([])

      get "/admin/groups/#{group.id}"

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'infos sensibles' do
    before do
      sign_in super_admin
      start_impersonating(referente)
    end

    it 'masque le texte dans le formulaire, champ désactivé' do
      get "/admin/child_supports/#{fiche.id}/edit", params: { r: 'true' }

      expect(response.body).to include('Infos sensibles')
      expect(response.body).to include(ChildSupportDecorator::SENSITIVE_INFORMATION_MASK)
      expect(response.body).not_to include(texte_sensible)
      expect(response.body).to match(/<textarea[^>]*disabled[^>]*id="child_support_sensitive_information"|<textarea[^>]*id="child_support_sensitive_information"[^>]*disabled/)
    end

    it 'masque le texte dans la page de la fiche' do
      get "/admin/child_supports/#{fiche.id}"

      expect(response.body).to include(ChildSupportDecorator::SENSITIVE_INFORMATION_MASK)
      expect(response.body).not_to include(texte_sensible)
    end

    it "n'affiche pas de masque quand le champ est vide" do
      fiche.update!(sensitive_information: nil)
      get "/admin/child_supports/#{fiche.id}"

      expect(response.body).not_to include(ChildSupportDecorator::SENSITIVE_INFORMATION_MASK)
    end
  end

  describe 'fin de la simulation' do
    before do
      sign_in super_admin
      start_impersonating(referente)
    end

    it 'rend la main au super admin' do
      delete '/admin/impersonation'

      expect(response).to redirect_to(admin_admin_user_path(referente))
      patch "/admin/child_supports/#{fiche.id}", params: { child_support: { parent_needs: 'Après' } }
      expect(flash[:alert].to_s).not_to include('Lecture seule')
    end

    it 'cesse si le compte simulé est désactivé entre-temps' do
      referente.update_column(:is_disabled, true)
      get '/admin/child_supports'

      expect(response.body).not_to include('impersonation-banner')
      expect(session[:impersonated_admin_user_id]).to be_nil
    end

    it 'cesse si le super admin perd son rôle' do
      super_admin.update_column(:user_role, 'contributor')
      get '/admin/child_supports'

      expect(session[:impersonated_admin_user_id]).to be_nil
    end

    it 'permet de se déconnecter' do
      delete destroy_admin_user_session_path

      expect(session[:impersonated_admin_user_id]).to be_nil
      get '/admin/child_supports'
      expect(response).to redirect_to(new_admin_user_session_path)
    end
  end
end
