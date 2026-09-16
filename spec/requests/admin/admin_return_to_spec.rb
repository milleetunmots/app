require 'rails_helper'

RSpec.describe 'Admin - retour à la fiche de suivi après modification d’un parent / enfant', type: :request do
  let(:supporter) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let!(:group) { FactoryBot.create(:group, started_at: Date.current.beginning_of_week(:monday)) }
  let!(:parent) { FactoryBot.create(:parent) }
  let!(:child) { FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active') }
  let!(:child_support) { child.child_support.tap { |cs| cs.update!(supporter: supporter) } }

  let(:return_path) { "/admin/child_supports/#{child_support.id}/edit?close_tab=1" }

  before { sign_in supporter }

  describe 'la fiche de suivi expose le lien crayon vers les fiches parent / enfant' do
    it 'pointe vers l’édition avec l’id de la fiche de suivi' do
      get "/admin/child_supports/#{child_support.id}/edit?r=true"

      expect(response.body).to include(
        "/admin/parents/#{parent.id}/edit?back_to_child_support_id=#{child_support.id}"
      )
      expect(response.body).to include(
        "/admin/children/#{child.id}/edit?back_to_child_support_id=#{child_support.id}"
      )
      expect(response.body).to include('js-scripted-tab-link')
    end
  end

  describe "l'URL de retour conserve le marqueur de fermeture d'onglet" do
    it 'préserve close_tab lors de la redirection vers l’onglet d’appel courant' do
      get "/admin/child_supports/#{child_support.id}/edit?close_tab=1"

      expect(response).to redirect_to(
        "/admin/child_supports/#{child_support.id}/edit?close_tab=1&r=true#appel-#{child_support.current_call_session}"
      )
    end
  end

  describe 'le formulaire parent / enfant transporte l’id de la fiche de suivi' do
    it 'ajoute un champ caché sur la fiche parent' do
      get "/admin/parents/#{parent.id}/edit", params: { back_to_child_support_id: child_support.id }

      expect(response.body).to include('name="back_to_child_support_id"')
      expect(response.body).to include("value=\"#{child_support.id}\"")
    end

    it 'ajoute un champ caché sur la fiche enfant' do
      get "/admin/children/#{child.id}/edit", params: { back_to_child_support_id: child_support.id }

      expect(response.body).to include('name="back_to_child_support_id"')
    end

    it "n'ajoute rien quand la fiche est ouverte sans retour" do
      get "/admin/parents/#{parent.id}/edit"

      expect(response.body).not_to include('name="back_to_child_support_id"')
    end
  end

  describe 'PATCH /admin/parents/:id' do
    it 'redirige vers la fiche de suivi en édition' do
      patch "/admin/parents/#{parent.id}", params: {
        back_to_child_support_id: child_support.id,
        parent: { first_name: 'Nouveau prénom' }
      }

      expect(response).to redirect_to(return_path)
      expect(parent.reload.first_name).to eq('Nouveau Prénom')
    end

    it 'conserve la redirection par défaut sans retour demandé' do
      patch "/admin/parents/#{parent.id}", params: { parent: { first_name: 'Sans retour' } }

      expect(response).to redirect_to("/admin/parents/#{parent.id}")
    end

    it 'ne redirige pas quand la validation échoue' do
      patch "/admin/parents/#{parent.id}", params: {
        back_to_child_support_id: child_support.id,
        parent: { first_name: '' }
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="back_to_child_support_id"')
    end
  end

  describe 'PATCH /admin/children/:id' do
    it 'redirige vers la fiche de suivi en édition' do
      patch "/admin/children/#{child.id}", params: {
        back_to_child_support_id: child_support.id,
        child: { first_name: 'Nouveau prénom' }
      }

      expect(response).to redirect_to(return_path)
      expect(child.reload.first_name).to eq('Nouveau Prénom')
    end

    it 'conserve la redirection par défaut sans retour demandé' do
      patch "/admin/children/#{child.id}", params: { child: { first_name: 'Sans retour' } }

      expect(response).to redirect_to("/admin/children/#{child.id}")
    end
  end
end
