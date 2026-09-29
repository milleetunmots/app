require 'rails_helper'

RSpec.describe 'Admin blocked send attempts', type: :request do
  describe 'en tant que super_admin' do
    before { sign_in FactoryBot.create(:admin_user, user_role: 'super_admin') }

    it 'liste les tentatives à traiter et affiche le détail' do
      attempt = FactoryBot.create(:blocked_send_attempt)

      get '/admin/blocked_send_attempts'
      expect(response.body).to include('non-whitelisted.example.com')

      get "/admin/blocked_send_attempts/#{attempt.id}"
      expect(response.body).to include('Relancer cet envoi')
      expect(response.body).to include('ajoute les valeurs détectées aux patterns autorisés')
    end

    it 'relance une tentative et la marque comme relancée' do
      attempt = FactoryBot.create(:blocked_send_attempt)
      service = instance_double(ProgramMessageService, errors: [], call: nil)
      allow(ProgramMessageService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(service)

      put "/admin/blocked_send_attempts/#{attempt.id}/relaunch"

      expect(attempt.reload.status).to eq('relaunched')
      expect(attempt.resolved_at).to be_present
    end

    it 'annonce les valeurs ajoutées aux patterns autorisés' do
      attempt = FactoryBot.create(:blocked_send_attempt)
      service = instance_double(ProgramMessageService, errors: [])
      allow(ProgramMessageService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(service)

      put "/admin/blocked_send_attempts/#{attempt.id}/relaunch"

      follow_redirect!
      expect(response.body).to include('Valeurs ajoutées aux patterns autorisés')
      expect(response.body).to include('non-whitelisted.example.com/page')
      expect(AllowedPattern.exists?(kind: 'url', match_type: 'exact')).to be(true)
    end

    # La session est en cookie (4 Ko) : tout lister ferait échouer la redirection
    # sur un CookieOverflow, alors même que le message est déjà parti.
    it 'tronque la liste des valeurs ajoutées au lieu de faire déborder le cookie' do
      values = Array.new(8) { |n| "https://partenaire#{n}.fr/page" }
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'url', detected_values: values)
      service = instance_double(ProgramMessageService, errors: [])
      allow(ProgramMessageService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(service)

      put "/admin/blocked_send_attempts/#{attempt.id}/relaunch"

      expect(flash[:notice]).to include('partenaire0.fr/page', 'et 3 autres')
      expect(flash[:notice]).not_to include('partenaire7.fr')
    end

    it 'ne parle pas de patterns autorisés pour un mot-clé, qui reste interdit' do
      attempt = FactoryBot.create(:blocked_send_attempt, kind: 'keyword', detected_values: ['carte cadeau'])
      service = instance_double(ProgramMessageService, errors: [])
      allow(ProgramMessageService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(service)

      put "/admin/blocked_send_attempts/#{attempt.id}/relaunch"

      follow_redirect!
      expect(response.body).to include('envoi a été relancé.')
      expect(response.body).not_to include('Valeurs ajoutées aux patterns autorisés')
      expect(AllowedPattern.count).to eq(0)
    end

    it "laisse la tentative en attente et affiche l'erreur quand la relance échoue" do
      attempt = FactoryBot.create(:blocked_send_attempt)
      service = instance_double(ProgramMessageService, errors: ['Aucun parent à contacter.'])
      allow(ProgramMessageService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(service)

      put "/admin/blocked_send_attempts/#{attempt.id}/relaunch"

      expect(attempt.reload.status).to eq('pending')
      follow_redirect!
      expect(response.body).to include('Aucun parent à contacter.')
    end

    it 'refuse de relancer une tentative déjà transmise au provider (surveillance)' do
      attempt = FactoryBot.create(:blocked_send_attempt, status: 'not_blocked')
      expect(ProgramMessageService).not_to receive(:new)

      put "/admin/blocked_send_attempts/#{attempt.id}/relaunch"

      expect(attempt.reload.status).to eq('not_blocked')
    end

    it 'refuse de relancer une tentative sans paramètres de relance' do
      attempt = FactoryBot.create(:blocked_send_attempt, replay_params: {})
      expect(ProgramMessageService).not_to receive(:new)

      put "/admin/blocked_send_attempts/#{attempt.id}/relaunch"

      expect(attempt.reload.status).to eq('pending')
      follow_redirect!
      expect(response.body).to include('envoi automatique')
    end
  end

  %w[contributor reader caller animator].each do |role|
    describe "en tant que #{role}" do
      before { sign_in FactoryBot.create(:admin_user, user_role: role) }

      it "n'a pas accès à la liste des envois bloqués" do
        get '/admin/blocked_send_attempts'
        expect(response).to redirect_to('/admin/children')
      end

      it 'ne peut pas relancer un envoi bloqué' do
        attempt = FactoryBot.create(:blocked_send_attempt)

        put "/admin/blocked_send_attempts/#{attempt.id}/relaunch"

        expect(attempt.reload.status).to eq('pending')
      end
    end
  end
end
