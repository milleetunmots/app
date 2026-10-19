require 'rails_helper'

RSpec.describe "Admin rattachement d'un enfant à un parent", type: :request do
  let(:texte) { 'Père placé en foyer' }
  let(:awa) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:autre_supporter) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let!(:groupe_actif) { FactoryBot.create(:group, started_at: 8.weeks.ago.prev_occurring(:monday), ended_at: 8.weeks.from_now) }
  let!(:groupe_fini) { FactoryBot.create(:group, started_at: 40.weeks.ago.prev_occurring(:monday), ended_at: 20.weeks.ago) }

  let!(:enfant_awa) do
    FactoryBot.create(:child, group: groupe_actif, group_status: 'active').tap { |enfant| enfant.child_support.update!(supporter: awa) }
  end
  let!(:parent_cible) { FactoryBot.create(:parent) }
  let!(:enfant_cible) { FactoryBot.create(:child, parent1: parent_cible, group: groupe_fini, group_status: 'stopped') }
  let(:fiche_cible) { enfant_cible.child_support }

  before do
    fiche_cible.update!(supporter: autre_supporter)
    fiche_cible.update!(sensitive_information: texte)
  end

  %w[caller animator].each do |role|
    context "avec une requête forgée d'un #{role} vers une famille suivie par quelqu'un d'autre" do
      let(:utilisateur) { role == 'caller' ? awa : FactoryBot.create(:admin_user, user_role: 'animator') }

      before do
        enfant_awa.child_support.update!(supporter: utilisateur)
        sign_in utilisateur
      end

      it "ne rattache pas l'enfant au parent (parent1_id)" do
        patch "/admin/children/#{enfant_awa.id}", params: { child: { parent1_id: parent_cible.id } }

        expect(enfant_awa.reload.parent1_id).not_to eq(parent_cible.id)
      end

      it "ne rattache pas l'enfant au parent (parent2_id)" do
        patch "/admin/children/#{enfant_awa.id}", params: { child: { parent2_id: parent_cible.id } }

        expect(enfant_awa.reload.parent2_id).not_to eq(parent_cible.id)
      end

      it "ne change pas le supporter de la fiche de l'autre famille" do
        patch "/admin/children/#{enfant_awa.id}", params: { child: { parent1_id: parent_cible.id } }

        expect(fiche_cible.reload.supporter_id).to eq(autre_supporter.id)
      end

      it "ne donne pas accès au texte sensible de l'autre famille" do
        patch "/admin/children/#{enfant_awa.id}", params: { child: { parent1_id: parent_cible.id } }
        get "/admin/child_supports/#{fiche_cible.id}/edit", params: { r: 'true' }

        expect(response.body).not_to include(texte)
      end

      it "n'empêche pas la modification des autres champs de l'enfant" do
        patch "/admin/children/#{enfant_awa.id}", params: { child: { parent1_id: parent_cible.id, first_name: 'Prénom Corrigé' } }

        expect(enfant_awa.reload.first_name).to eq('Prénom Corrigé')
      end
    end
  end

  context "quand un caller rattache l'enfant à un parent sans enfant" do
    it "l'accepte" do
      nouveau_parent = FactoryBot.create(:parent)
      sign_in awa

      patch "/admin/children/#{enfant_awa.id}", params: { child: { parent2_id: nouveau_parent.id } }

      expect(enfant_awa.reload.parent2_id).to eq(nouveau_parent.id)
    end
  end

  context "quand un caller rattache l'enfant à un parent d'une famille qu'il suit lui-même" do
    it "l'accepte" do
      propre_parent = FactoryBot.create(:parent)
      propre_enfant = FactoryBot.create(:child, parent1: propre_parent, group: groupe_fini, group_status: 'stopped')
      propre_enfant.child_support.update!(supporter: awa)
      sign_in awa

      patch "/admin/children/#{enfant_awa.id}", params: { child: { parent2_id: propre_parent.id } }

      expect(enfant_awa.reload.parent2_id).to eq(propre_parent.id)
    end
  end

  context "quand le formulaire renvoie le même parent que celui déjà enregistré" do
    it "ne bloque pas l'enregistrement, même si ce parent a une autre fiche suivie par quelqu'un d'autre" do
      enfant_awa.update_columns(parent1_id: parent_cible.id)
      sign_in awa

      patch "/admin/children/#{enfant_awa.id}", params: { child: { parent1_id: parent_cible.id, first_name: 'Prénom Corrigé' } }

      expect(enfant_awa.reload.first_name).to eq('Prénom Corrigé')
    end
  end

  %w[contributor super_admin].each do |role|
    context "quand un #{role} rattache l'enfant à une autre famille" do
      it "l'accepte" do
        sign_in FactoryBot.create(:admin_user, user_role: role)

        patch "/admin/children/#{enfant_awa.id}", params: { child: { parent2_id: parent_cible.id } }

        expect(enfant_awa.reload.parent2_id).to eq(parent_cible.id)
      end
    end
  end
end
