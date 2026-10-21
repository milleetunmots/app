require 'rails_helper'

RSpec.describe "Admin répartition des fiches d'une cohorte : supporters non éligibles", type: :request do
  let!(:group) { FactoryBot.create(:group) }
  let!(:enfants) { FactoryBot.create_list(:child, 2, group: group, group_status: 'active') }
  let(:caller_actif) { FactoryBot.create(:admin_user, user_role: 'caller') }
  let(:contributor) { FactoryBot.create(:admin_user, user_role: 'contributor') }
  let(:caller_desactive) { FactoryBot.create(:admin_user, user_role: 'caller', is_disabled: true) }

  def mission(airtable_id, nom)
    double("mission #{nom}", airtable_caller_id: airtable_id, child_supports_count: 1, age_range: nil).tap do |double|
      allow(double).to receive(:[]).with('Name').and_return("#{nom} - #1")
    end
  end

  def repartir_avec(supporters)
    missions = supporters.each_with_index.map { |user, index| mission("rec#{index}", user.name) }
    allow(Airtables::Call).to receive(:call_missions_by_name).and_return(missions)
    supporters.each_with_index do |user, index|
      allow(Airtables::Caller).to receive(:caller_id_by_airtable_caller_id).with("rec#{index}").and_return(user.id)
    end
    post "/admin/groups/#{group.id}/perform_distribute_child_support", params: { group: { name: 'Cohorte test' } }
  end

  before do
    sign_in FactoryBot.create(:admin_user, user_role: 'super_admin')
    allow(Group::DistributeChildSupportsToSupportersJob).to receive(:perform_later)
    allow(Rollbar).to receive(:error)
  end

  context "quand tous les supporters sont des caller ou animator actifs" do
    it "lance la répartition sans rien signaler" do
      repartir_avec([caller_actif, FactoryBot.create(:admin_user, user_role: 'animator')])

      expect(Group::DistributeChildSupportsToSupportersJob).to have_received(:perform_later)
      expect(Rollbar).not_to have_received(:error)
    end
  end

  context "quand un supporter issu d'Airtable est un contributor" do
    it "lance quand même la répartition" do
      repartir_avec([caller_actif, contributor])

      expect(Group::DistributeChildSupportsToSupportersJob).to have_received(:perform_later)
    end

    it "le signale dans Rollbar avec l'identifiant de la cohorte, son identifiant et son rôle" do
      repartir_avec([caller_actif, contributor])

      expect(Rollbar).to have_received(:error).with(
        anything,
        hash_including(group_id: group.id, supporters: [{ id: contributor.id, role: 'contributor', disabled: false }])
      )
    end

    it "n'envoie ni nom ni e-mail à Rollbar" do
      repartir_avec([caller_actif, contributor])

      expect(Rollbar).to have_received(:error) do |_source, contexte|
        expect(contexte.to_s).not_to include(contributor.name)
        expect(contexte.to_s).not_to include(contributor.email)
      end
    end
  end

  context "quand un supporter issu d'Airtable est désactivé" do
    it "le signale dans Rollbar" do
      repartir_avec([caller_actif, caller_desactive])

      expect(Rollbar).to have_received(:error).with(
        anything,
        hash_including(supporters: [{ id: caller_desactive.id, role: 'caller', disabled: true }])
      )
    end
  end
end
