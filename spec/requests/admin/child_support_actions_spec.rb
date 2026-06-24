require 'rails_helper'

RSpec.describe 'Admin child support actions', type: :request do
  let!(:group) { FactoryBot.create(:group, started_at: 8.weeks.ago.prev_occurring(:monday), ended_at: 8.weeks.from_now) }
  let!(:child) { FactoryBot.create(:child, group: group, group_status: 'stopped') }
  let!(:child_support) do
    cs = child.child_support
    cs.update!(support_stopped_for_unassigned_number_at: 1.day.ago)
    cs
  end

  context "quand l'accompagnement est arrêté pour numéro erroné" do
    it "affiche 'Reprendre l'accompagnement' pour un contributeur" do
      sign_in FactoryBot.create(:admin_user, user_role: 'contributor')
      get "/admin/child_supports/#{child_support.id}"
      expect(response.body).to include("Reprendre l&#39;accompagnement")
    end

    it "n'affiche pas 'Reprendre l'accompagnement' pour un caller" do
      sign_in FactoryBot.create(:admin_user, user_role: 'caller')
      get "/admin/child_supports/#{child_support.id}"
      expect(response.body).not_to include("Reprendre l&#39;accompagnement")
    end
  end

  describe 'POST /admin/restart_support_form/perform — gating serveur du motif unreachable_number' do
    let(:perform_path) { '/admin/restart_support_form/perform' }
    let(:params) do
      { child_support_id: child_support.id, unreachable_number: 'unreachable_number' }
    end

    context "en tant que caller" do
      before { sign_in FactoryBot.create(:admin_user, user_role: 'caller') }

      it "ne réactive pas l'enfant stopped" do
        post perform_path, params: params
        expect(child.reload.group_status).to eq('stopped')
      end

      it "ne supprime pas le timestamp d'arrêt pour numéro erroné" do
        post perform_path, params: params
        expect(child_support.reload.support_stopped_for_unassigned_number_at).to be_present
      end
    end

    context "en tant que contributor" do
      before { sign_in FactoryBot.create(:admin_user, user_role: 'contributor') }

      it "réactive l'enfant stopped" do
        post perform_path, params: params
        expect(child.reload.group_status).to eq('active')
      end

      it "supprime le timestamp d'arrêt pour numéro erroné" do
        post perform_path, params: params
        expect(child_support.reload.support_stopped_for_unassigned_number_at).to be_nil
      end
    end
  end
end
