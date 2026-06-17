require 'rails_helper'

RSpec.describe ChildSupport::CallerRestartSupportService do
  let!(:supporter) { FactoryBot.create(:admin_user, user_role: 'contributor') }

  describe 'reprise pour numéro injoignable' do
    let!(:group) { FactoryBot.create(:group, started_at: 8.weeks.ago.prev_occurring(:monday), ended_at: 8.weeks.from_now) }
    let!(:child) do
      FactoryBot.create(:child, group: group, group_status: 'stopped',
                                should_contact_parent1: false,
                                contact_parent1_unset_for_unassigned_number: true)
    end
    let!(:child_support) do
      cs = child.child_support
      cs.update!(support_stopped_for_unassigned_number_at: 1.day.ago)
      cs
    end

    subject do
      described_class.new(supporter.id, child_support.id, ['unreachable_number'], 'numéro mis à jour').call
    end

    it "réactive les enfants stopped dont la cohorte n'est pas terminée" do
      subject
      expect(child.reload.group_status).to eq 'active'
      expect(child.reload.group_end).to be_nil
    end

    it "recoche uniquement les contacts décochés par l'arrêt et efface les marqueurs" do
      subject
      expect(child.reload.should_contact_parent1).to be true
      expect(child.reload.contact_parent1_unset_for_unassigned_number).to be false
    end

    it "ajoute la note de redémarrage dédiée" do
      subject
      expect(child_support.reload.important_information)
        .to include('suite à la mise à jour du numéro à contacter')
    end

    it "renseigne les champs restart" do
      subject
      expect(child_support.reload.restart_support_caller_id).to eq supporter.id
      expect(child_support.reload.restart_support_details).to include('unreachable_number')
    end

    it "n'ajoute pas le tag 'accompagnement redemarre'" do
      subject
      expect(child_support.reload.tag_list).not_to include('accompagnement redemarre')
    end

    it "efface le timestamp d'arrêt pour numéro erroné" do
      subject
      expect(child_support.reload.support_stopped_for_unassigned_number_at).to be_nil
    end

    it "ne réactive pas si la cohorte est terminée et renvoie une erreur" do
      group.update!(ended_at: 1.day.ago)
      result = subject
      expect(child.reload.group_status).to eq 'stopped'
      expect(result.error).to be_present
    end

    it "réactive si la cohorte est ouverte (ended_at: nil)" do
      group.update!(ended_at: nil)
      subject
      expect(child.reload.group_status).to eq 'active'
    end
  end

  describe 'reprise classique (désengagement) inchangée' do
    let!(:group) { FactoryBot.create(:group, started_at: 8.weeks.ago.prev_occurring(:monday), ended_at: 8.weeks.from_now) }
    let!(:child) { FactoryBot.create(:child, group: group, group_status: 'disengaged') }
    let!(:child_support) { child.child_support }

    subject do
      described_class.new(supporter.id, child_support.id, ['unavailability'], '').call
    end

    it "réactive les enfants disengaged et ajoute le tag" do
      subject
      expect(child.reload.group_status).to eq 'active'
      expect(child_support.reload.tag_list).to include('accompagnement redemarre')
    end
  end
end
