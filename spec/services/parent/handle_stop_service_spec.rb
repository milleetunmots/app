require 'rails_helper'

RSpec.describe Parent::HandleStopService do
  describe '#call' do
    def call_service(phone_number)
      described_class.new(
        phone_number: Phonelib.parse(phone_number).e164,
        occurred_at: Time.zone.local(2026, 11, 18, 10),
        spot_hit_message_id: 'sms-42'
      ).call
    end

    it "arrête aussi l'enfant archivé du parent" do
      parent = FactoryBot.create(:parent, phone_number: '0612345678')
      group = FactoryBot.create(:group)
      child = FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active')
      archived_child = FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active', discarded_at: 1.day.ago)

      service = call_service('0612345678')

      expect(service.errors).to be_empty
      [child, archived_child].each do |stopped_child|
        expect(stopped_child.reload).to have_attributes(should_contact_parent1: false, group_status: 'stopped')
      end
    end

    it 'traite tous les parents qui portent le numéro, parents supprimés compris' do
      group = FactoryBot.create(:group)
      parent = FactoryBot.create(:parent, phone_number: '0612345678')
      other_family_parent = FactoryBot.create(:parent, phone_number: '0612345678')
      discarded_parent = FactoryBot.create(:parent, phone_number: '0612345678', discarded_at: 1.day.ago)
      child = FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active')
      other_family_child = FactoryBot.create(:child, parent1: other_family_parent, group: group, group_status: 'active')
      discarded_parent_child = FactoryBot.create(:child, parent1: discarded_parent, group: group, group_status: 'paused')

      service = call_service('0612345678')

      expect(service.errors).to be_empty
      [child, other_family_child, discarded_parent_child].each do |stopped_child|
        expect(stopped_child.reload).to have_attributes(should_contact_parent1: false, group_status: 'stopped')
      end
      [parent, other_family_parent, discarded_parent].each do |stopping_parent|
        expect(Events::TextMessage.where(related: stopping_parent, body: 'STOP').count).to eq(1)
      end
    end

    it "décoche les deux parents d'une famille qui partagent le numéro et arrête l'enfant" do
      parent1 = FactoryBot.create(:parent, phone_number: '0612345678')
      parent2 = FactoryBot.create(:parent, phone_number: '0612345678')
      child = FactoryBot.create(
        :child,
        parent1: parent1, parent2: parent2, should_contact_parent2: true,
        group: FactoryBot.create(:group), group_status: 'active'
      )

      service = call_service('0612345678')

      expect(service.errors).to be_empty
      expect(child.reload).to have_attributes(should_contact_parent1: false, should_contact_parent2: false, group_status: 'stopped')
    end

    it 'rattache le message STOP à la campagne RCS' do
      parent = FactoryBot.create(:parent, phone_number: '0612345678')

      service = described_class.new(
        phone_number: parent.reload.phone_number, occurred_at: Time.zone.local(2026, 11, 18, 10), spot_hit_rcs_id: '45878'
      ).call

      expect(service.errors).to be_empty
      expect(Events::TextMessage.find_by(related: parent, body: 'STOP')).to have_attributes(spot_hit_rcs_id: '45878', spot_hit_message_id: nil)
    end

    it "remonte une erreur et ne décoche personne si le message STOP n'a pas pu être créé" do
      parent = FactoryBot.create(:parent, phone_number: '0612345678')
      child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'active')

      service = described_class.new(phone_number: parent.reload.phone_number, occurred_at: nil, spot_hit_message_id: 'sms-42').call

      expect(service.errors).to contain_exactly(
        { message: "Le STOP n'a pas pu être enregistré", context: { parent_id: parent.id, errors: ['Date doit être rempli(e)'] } }
      )
      expect(child.reload).to have_attributes(should_contact_parent1: true, group_status: 'active')
    end
  end
end
