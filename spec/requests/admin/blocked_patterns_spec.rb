require 'rails_helper'

RSpec.describe 'Admin blocked patterns', type: :request do
  describe "en tant qu'admin habilité (super_admin)" do
    before { sign_in FactoryBot.create(:admin_user, user_role: 'super_admin') }

    it 'peut consulter la liste et ajouter un terme interdit' do
      post '/admin/blocked_patterns', params: { blocked_pattern: { kind: 'keyword', value: 'compte bloqué' } }
      expect(BlockedPattern.exists?(kind: 'keyword', value: 'compte bloqué')).to be true

      get '/admin/blocked_patterns'
      expect(response.body).to include('compte bloqué')
    end

    it 'peut supprimer un terme (aucune garde, contrairement aux patterns URL)' do
      pattern = FactoryBot.create(:blocked_pattern)

      expect do
        delete "/admin/blocked_patterns/#{pattern.id}"
      end.to change(BlockedPattern, :count).by(-1)
    end

    it "affiche l'erreur de validation quand le terme est trop court une fois normalisé" do
      expect do
        post '/admin/blocked_patterns', params: { blocked_pattern: { kind: 'keyword', value: 'Là' } }
      end.not_to change(BlockedPattern, :count)

      expect(response.body).to include('doit contenir au moins 3 caractères alphanumériques une fois normalisée')
    end

    it "affiche l'erreur de validation quand le terme est un doublon sous une autre graphie" do
      FactoryBot.create(:blocked_pattern, value: 'Vérifié')

      expect do
        post '/admin/blocked_patterns', params: { blocked_pattern: { kind: 'keyword', value: 'verifie' } }
      end.not_to change(BlockedPattern, :count)

      expect(response.body).to include('existe déjà sous une autre graphie')
    end
  end

  %w[contributor reader caller animator].each do |role|
    describe "en tant que #{role}" do
      before { sign_in FactoryBot.create(:admin_user, user_role: role) }

      it "n'a pas accès à la liste des termes interdits" do
        get '/admin/blocked_patterns'
        expect(response).to redirect_to('/admin/children')
      end

      it "n'a pas accès en écriture (création)" do
        expect do
          post '/admin/blocked_patterns', params: { blocked_pattern: { kind: 'keyword', value: 'terme interdit' } }
        end.not_to change(BlockedPattern, :count)
      end
    end
  end
end
