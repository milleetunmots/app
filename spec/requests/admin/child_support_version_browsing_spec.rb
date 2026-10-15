require 'rails_helper'

RSpec.describe "Admin consultation d'une ancienne version d'une fiche de suivi", type: :request do
  let(:texte) { 'Père placé en foyer' }
  let(:ancien_supporter) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:supporter_actuel) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let!(:fiche) do
    FactoryBot.create(:child_support, supporter: ancien_supporter).tap do |child_support|
      child_support.update!(notes: 'v1')
      child_support.update!(supporter_id: supporter_actuel.id)
      child_support.update!(sensitive_information: texte, ok_for_solicitation: false)
    end
  end
  let(:chemin_version) { "/admin/child_supports/#{fiche.id}?version=1" }

  def etat_de_la_fiche
    fiche.reload
    { supporter_id: fiche.supporter_id, texte: fiche.sensitive_information, menu: fiche.ok_for_solicitation }
  end

  %w[reader animator contributor super_admin].each do |role|
    context "avec une requête de modification forgée par un #{role} qui n'est pas le supporter" do
      it "ne change ni le supporter, ni le texte sensible, ni le menu" do
        sign_in FactoryBot.create(:admin_user, user_role: role)
        avant = etat_de_la_fiche

        patch chemin_version, params: { child_support: { notes: 'x' } }

        expect(etat_de_la_fiche).to eq(avant)
      end
    end
  end

  context "avec une requête de modification forgée par l'ancien supporter" do
    it "ne lui rend pas la fiche et n'efface rien" do
      sign_in ancien_supporter
      avant = etat_de_la_fiche

      patch chemin_version, params: { child_support: { notes: 'x' } }

      expect(etat_de_la_fiche).to eq(avant)
    end
  end

  context "avec une modification faite par le supporter actuel, même avec ?version=" do
    it "s'applique à la fiche actuelle sans toucher au texte ni au supporter" do
      sign_in supporter_actuel

      patch chemin_version, params: { child_support: { notes: 'Note du supporter' } }

      fiche.reload
      expect(fiche.notes).to eq('Note du supporter')
      expect(fiche.sensitive_information).to eq(texte)
      expect(fiche.supporter_id).to eq(supporter_actuel.id)
      expect(fiche.ok_for_solicitation).to be(false)
    end
  end

  describe "consultation (GET)" do
    it "affiche l'ancienne version à un super_admin, sans le texte sensible" do
      sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')

      get chemin_version

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(texte)
    end

    it "ouvre la fiche actuelle à son supporter" do
      sign_in supporter_actuel

      get "/admin/child_supports/#{fiche.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(texte)
    end

    it "refuse l'ancienne version à l'ancien supporter, qui n'a plus accès à la fiche" do
      sign_in ancien_supporter

      get chemin_version

      expect(response).to have_http_status(:found)
      expect(response.body).not_to include(texte)
    end
  end
end
