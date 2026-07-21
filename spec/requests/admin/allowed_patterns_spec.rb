require 'rails_helper'

RSpec.describe 'Admin allowed patterns', type: :request do
  describe "en tant qu'admin habilité (super_admin)" do
    before { sign_in FactoryBot.create(:admin_user, user_role: 'super_admin') }

    it 'peut consulter la liste des patterns autorisés' do
      get '/admin/allowed_patterns'
      expect(response).to have_http_status(:ok)
    end

    it 'peut ajouter un domaine autorisé et le voir apparaître dans la liste' do
      post '/admin/allowed_patterns', params: { allowed_pattern: { kind: 'url', match_type: 'domain', value: 'monpartenaire.fr' } }
      expect(AllowedPattern.exists?(kind: 'url', match_type: 'domain', value: 'monpartenaire.fr')).to be true

      get '/admin/allowed_patterns'
      expect(response.body).to include('monpartenaire.fr')
    end

    it "rejette la création d'un kind non supporté" do
      expect do
        post '/admin/allowed_patterns', params: { allowed_pattern: { kind: 'keyword', match_type: 'domain', value: 'test' } }
      end.not_to change(AllowedPattern, :count)
    end

    it "rejette la création d'un match_type incohérent avec le kind" do
      expect do
        post '/admin/allowed_patterns', params: { allowed_pattern: { kind: 'url', match_type: 'contains', value: 'test.fr' } }
      end.not_to change(AllowedPattern, :count)
    end

    it 'rejette un doublon kind/match_type/value' do
      FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'youtube.com')

      expect do
        post '/admin/allowed_patterns', params: { allowed_pattern: { kind: 'url', match_type: 'domain', value: 'youtube.com' } }
      end.not_to change(AllowedPattern, :count)
    end

    it "refuse la suppression d'un domaine encore utilisé par un Media::Form" do
      allowed_pattern = FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'youtube.com')
      FactoryBot.create(:media_form, url: 'https://youtube.com/watch?v=abc123')

      delete "/admin/allowed_patterns/#{allowed_pattern.id}"

      expect(AllowedPattern.exists?(allowed_pattern.id)).to be true
    end

    it "autorise la suppression d'un domaine non utilisé" do
      allowed_pattern = FactoryBot.create(:allowed_pattern, kind: 'url', match_type: 'domain', value: 'monancienpartenaire.fr')

      delete "/admin/allowed_patterns/#{allowed_pattern.id}"

      expect(AllowedPattern.exists?(allowed_pattern.id)).to be false
    end
  end

  %w[contributor reader caller animator].each do |role|
    describe "en tant que #{role}" do
      before { sign_in FactoryBot.create(:admin_user, user_role: role) }

      it "n'a pas accès en lecture à la liste des patterns autorisés" do
        get '/admin/allowed_patterns'
        expect(response).to redirect_to('/admin/children')
      end

      it "n'a pas accès en écriture (création)" do
        expect do
          post '/admin/allowed_patterns', params: { allowed_pattern: { kind: 'url', match_type: 'domain', value: 'test.fr' } }
        end.not_to change(AllowedPattern, :count)
      end
    end
  end
end
