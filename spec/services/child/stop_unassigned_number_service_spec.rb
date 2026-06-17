require 'rails_helper'

RSpec.describe Child::StopUnassignedNumberService do
  let!(:group) { FactoryBot.create(:group, started_at: 8.weeks.ago.prev_occurring(:monday), ended_at: 8.weeks.from_now) }
  let!(:child) { FactoryBot.create(:child, group: group, group_status: 'active', should_contact_parent1: true) }
  let!(:child_support) { child.child_support }

  before(:each) do
    child_support.update!(call0_status: 'Numéro erroné')
  end

  subject { described_class.new.call }

  it "stoppe l'accompagnement (comportement existant conservé)" do
    subject
    expect(child.reload.group_status).to eq 'stopped'
    expect(child_support.reload.important_information).to include('pour cause de numéro erroné')
  end

  it "pose le timestamp d'arrêt pour numéro erroné" do
    subject
    expect(child_support.reload.support_stopped_for_unassigned_number_at).to be_present
  end

  it "décoche should_contact_parent1 et mémorise qu'il a été décoché par l'arrêt" do
    subject
    expect(child.reload.should_contact_parent1).to be false
    expect(child.reload.contact_parent1_unset_for_unassigned_number).to be true
  end

  it "ne mémorise pas un flag qui était déjà décoché" do
    child.update!(should_contact_parent1: false)
    subject
    expect(child.reload.contact_parent1_unset_for_unassigned_number).to be false
  end

  it "décoche should_contact_parent2 et mémorise qu'il a été décoché par l'arrêt" do
    parent2 = FactoryBot.create(:parent)
    child_with_parent2 = FactoryBot.create(:child, group: group, group_status: 'active', should_contact_parent2: true, parent2: parent2)
    cs = child_with_parent2.child_support
    cs.update!(call0_status: 'Numéro erroné')

    described_class.new.call

    expect(child_with_parent2.reload.should_contact_parent2).to be false
    expect(child_with_parent2.reload.contact_parent2_unset_for_unassigned_number).to be true
  end
end
