require 'rails_helper'

RSpec.describe 'Admin - détection d’une fiche parent / enfant / suivi périmée', type: :request do
  let(:admin_user) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let!(:group) { FactoryBot.create(:group, started_at: Date.current.beginning_of_week(:monday)) }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) { FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active') }
  let!(:child_support) { child.child_support.tap { |cs| cs.update!(supporter: admin_user) } }

  describe 'GET /parent-updated-at/:id' do
    context 'connecté' do
      before { sign_in admin_user }

      it 'renvoie la date de dernière sauvegarde en base' do
        get "/parent-updated-at/#{parent.id}"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['updated_at']).to eq(parent.reload.updated_at.as_json)
      end

      it 'reflète une sauvegarde faite entre-temps' do
        get "/parent-updated-at/#{parent.id}"
        before_update = response.parsed_body['updated_at']

        travel_to(2.minutes.from_now) { parent.update!(job: 'Boulanger') }

        get "/parent-updated-at/#{parent.id}"
        expect(response.parsed_body['updated_at']).not_to eq(before_update)
      end

      it 'renvoie 404 pour une fiche inconnue' do
        expect { get '/parent-updated-at/0' }.to raise_error(ActionController::RoutingError)
      end
    end

    it 'exige une session admin' do
      get "/parent-updated-at/#{parent.id}"

      expect(response).to redirect_to(new_admin_user_session_path)
    end
  end

  describe 'GET /child-updated-at/:id' do
    before { sign_in admin_user }

    it 'renvoie la date de dernière sauvegarde en base' do
      get "/child-updated-at/#{child.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['updated_at']).to eq(child.reload.updated_at.as_json)
    end
  end

  describe 'GET /child-support-updated-at/:id' do
    before { sign_in admin_user }

    it 'renvoie la date de dernière sauvegarde en base' do
      get "/child-support-updated-at/#{child_support.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['updated_at']).to eq(child_support.reload.updated_at.as_json)
    end

    it 'reflète une sauvegarde faite entre-temps' do
      get "/child-support-updated-at/#{child_support.id}"
      before_update = response.parsed_body['updated_at']

      travel_to(2.minutes.from_now) { child_support.update!(call0_notes: 'Rappeler demain') }

      get "/child-support-updated-at/#{child_support.id}"
      expect(response.parsed_body['updated_at']).to be > before_update
    end
  end

  describe 'le formulaire d’édition déclare l’URL de vérification' do
    before { sign_in admin_user }

    it 'sur la fiche parent' do
      get "/admin/parents/#{parent.id}/edit"

      expect(response.body).to include('js-form-freshness')
      expect(response.body).to include("data-url=\"/parent-updated-at/#{parent.id}\"")
      expect(response.body).to include("data-updated-at=\"#{parent.reload.updated_at.iso8601(3)}\"")
    end

    it 'sur la fiche enfant' do
      get "/admin/children/#{child.id}/edit"

      expect(response.body).to include('js-form-freshness')
      expect(response.body).to include("data-url=\"/child-updated-at/#{child.id}\"")
      expect(response.body).to include("data-updated-at=\"#{child.reload.updated_at.iso8601(3)}\"")
    end

    it 'sur la fiche de suivi' do
      get "/admin/child_supports/#{child_support.id}/edit?r=true"

      expect(response.body).to include('js-form-freshness')
      expect(response.body).to include("data-url=\"/child-support-updated-at/#{child_support.id}\"")
      expect(response.body).to include("data-updated-at=\"#{child_support.reload.updated_at.iso8601(3)}\"")
    end

    it 'mais pas sur un formulaire de création' do
      get '/admin/parents/new'

      expect(response.body).not_to include('js-form-freshness')
    end
  end
end
