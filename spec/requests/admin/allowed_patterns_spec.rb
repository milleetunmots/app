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

    # Contrat dont dépend admin/allowed_patterns.js pour restreindre la liste au
    # kind sélectionné : toutes les options sont rendues, étiquetées data-kinds.
    describe 'formulaire' do
      it 'rend toutes les options de match_type, étiquetées des kinds auxquels elles valent' do
        get '/admin/allowed_patterns/new'

        select = response.body[%r{<select[^>]*id="allowed_pattern_match_type".*?</select>}m]
        expect(select).to include('data-kinds="url" value="domain"')
        expect(select).to include('data-kinds="url phone_number" value="exact"')
      end

      it 'expose les deux kinds, sur les identifiants attendus par le script' do
        get '/admin/allowed_patterns/new'

        expect(response.body).to include('id="allowed_pattern_kind"')
        expect(response.body).to match(%r{<select[^>]*id="allowed_pattern_kind".*?value="phone_number".*?</select>}m)
      end

      # Second contrat du script : il pioche le hint de `value` dans data-hints,
      # sur les clés "kind/match_type".
      it 'expose tous les hints de value, et rend celui de la sélection par défaut' do
        get '/admin/allowed_patterns/new'

        expect(rendered_value_hints.keys).to contain_exactly('url/domain', 'url/exact', 'phone_number/exact')
        expect(rendered_value_hint).to eq rendered_value_hints['url/domain']
      end

      it 'rend, en édition, le hint du couple enregistré' do
        allowed_pattern = FactoryBot.create(:allowed_pattern, kind: 'phone_number', match_type: 'exact', value: '0810123456')

        get "/admin/allowed_patterns/#{allowed_pattern.id}/edit"

        expect(rendered_value_hint).to eq rendered_value_hints['phone_number/exact']
      end
    end

    it 'peut ajouter un numéro autorisé, canonicalisé à l\'enregistrement' do
      post '/admin/allowed_patterns', params: { allowed_pattern: { kind: 'phone_number', match_type: 'exact', value: '+33 810 12 34 56' } }

      expect(AllowedPattern.exists?(kind: 'phone_number', match_type: 'exact', value: '0810123456')).to be true
    end

    it "rejette un match_type de numéro réservé aux URLs" do
      expect do
        post '/admin/allowed_patterns', params: { allowed_pattern: { kind: 'phone_number', match_type: 'domain', value: '0810123456' } }
      end.not_to change(AllowedPattern, :count)
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

  def rendered_value_input
    response.body[/<input[^>]*id="allowed_pattern_value"[^>]*>/]
  end

  def rendered_value_hints
    JSON.parse(CGI.unescapeHTML(rendered_value_input[/data-hints="([^"]*)"/, 1]))
  end

  def rendered_value_hint
    CGI.unescapeHTML(response.body[%r{id="allowed_pattern_value_input".*?<p class="inline-hints">(.*?)</p>}m, 1])
  end
end
