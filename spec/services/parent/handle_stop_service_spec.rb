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

    describe "statut de l'enfant dont plus aucun parent n'est à contacter" do
      %w[active paused].each do |group_status|
        it "arrête l'enfant en cohorte au statut #{group_status} et date la fin de cohorte" do
          travel_to Time.zone.local(2026, 11, 18, 10)
          parent = FactoryBot.create(:parent, phone_number: '0612345678')
          child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: group_status)

          call_service('0612345678')

          expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'stopped', group_end: Date.new(2026, 11, 18))
        end
      end

      it "laisse désengagé l'enfant désengagé, avec sa fin de cohorte" do
        parent = FactoryBot.create(:parent, phone_number: '0612345678')
        child = FactoryBot.create(
          :child,
          parent1: parent, group: FactoryBot.create(:group), group_status: 'disengaged', group_end: Date.new(2026, 10, 1)
        )

        call_service('0612345678')

        expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'disengaged', group_end: Date.new(2026, 10, 1))
      end

      it "n'arrête pas l'enfant actif sorti de sa cohorte, un enfant arrêté devant en avoir une" do
        parent = FactoryBot.create(:parent, phone_number: '0612345678')
        child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'active')
        child.group_id = nil
        child.save(validate: false)

        call_service('0612345678')

        expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'active', group_end: nil)
      end

      it "passe en non accompagné l'enfant sur liste d'attente, sans fin de cohorte" do
        parent = FactoryBot.create(:parent, phone_number: '0612345678')
        child = FactoryBot.create(:child, parent1: parent, group: nil, group_status: 'waiting')

        call_service('0612345678')

        expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'not_supported', group_end: nil)
      end

      it "laisse arrêté l'enfant déjà arrêté, avec sa fin de cohorte" do
        parent = FactoryBot.create(:parent, phone_number: '0612345678')
        child = FactoryBot.create(
          :child,
          parent1: parent, group: FactoryBot.create(:group), group_status: 'stopped', group_end: Date.new(2026, 9, 2)
        )

        call_service('0612345678')

        expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'stopped', group_end: Date.new(2026, 9, 2))
      end

      it "laisse non accompagné l'enfant sans cohorte" do
        parent = FactoryBot.create(:parent, phone_number: '0612345678')
        child = FactoryBot.create(:child, parent1: parent, group: nil, group_status: 'not_supported')

        call_service('0612345678')

        expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'not_supported', group_end: nil)
      end
    end

    it "arrête l'enfant sans parent 2 même si « contacter parent 2 » est coché" do
      parent = FactoryBot.create(:parent, phone_number: '0612345678')
      child = FactoryBot.create(
        :child,
        parent1: parent, parent2: nil, should_contact_parent2: true,
        group: FactoryBot.create(:group), group_status: 'active'
      )

      call_service('0612345678')

      expect(child.reload).to have_attributes(should_contact_parent1: false, group_status: 'stopped')
    end

    it 'décoche le parent sur tous ses enfants' do
      parent = FactoryBot.create(:parent, phone_number: '0612345678')
      waiting_child = FactoryBot.create(:child, parent1: parent, group: nil, group_status: 'waiting')
      paused_child = FactoryBot.create(:child, parent1: parent, group: FactoryBot.create(:group), group_status: 'paused')

      call_service('0612345678')

      expect(paused_child.reload).to have_attributes(should_contact_parent1: false, group_status: 'stopped')
      expect(waiting_child.reload).to have_attributes(should_contact_parent1: false, group_status: 'not_supported')
    end

    describe 'STOP simultanés des deux parents', js: true do
      # Sans transaction de test, chaque thread a sa propre connexion et le verrou est réellement posé.
      self.use_transactional_tests = false

      it "arrête l'enfant quand les deux parents répondent STOP au même instant par deux canaux" do
        parent1 = FactoryBot.create(:parent, phone_number: '0611111111')
        parent2 = FactoryBot.create(:parent, phone_number: '0622222222')
        child = FactoryBot.create(
          :child,
          parent1: parent1, parent2: parent2, should_contact_parent2: true,
          group: FactoryBot.create(:group), group_status: 'active'
        )
        rcs_stop = described_class.new(phone_number: parent1.reload.phone_number, occurred_at: Time.zone.now, spot_hit_rcs_id: '45878')
        sms_stop = described_class.new(phone_number: parent2.reload.phone_number, occurred_at: Time.zone.now, spot_hit_message_id: 'sms-42')
        both_read_child = Concurrent::CountDownLatch.new(2)
        [rcs_stop, sms_stop].each do |service|
          allow(service).to receive(:parent_to_contact?).and_wrap_original do |original, read_child|
            both_read_child.count_down
            both_read_child.wait(1)
            original.call(read_child)
          end
        end

        threads = [rcs_stop, sms_stop].map do |service|
          Thread.new { ActiveRecord::Base.connection_pool.with_connection { service.call } }
        end

        expect(threads.map(&:value).flat_map(&:errors)).to be_empty
        expect(child.reload).to have_attributes(should_contact_parent1: false, should_contact_parent2: false, group_status: 'stopped')
      end
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

    it "n'enregistre aucun STOP ni ne décoche personne si le STOP d'un des parents du numéro échoue" do
      group = FactoryBot.create(:group)
      parent = FactoryBot.create(:parent, phone_number: '0612345678')
      failing_parent = FactoryBot.create(:parent, phone_number: '0612345678')
      child = FactoryBot.create(:child, parent1: parent, group: group, group_status: 'active')
      service = described_class.new(phone_number: parent.reload.phone_number, occurred_at: Time.zone.now, spot_hit_message_id: 'sms-42')
      allow(service).to receive(:stop_message_created?).and_wrap_original do |original, stopping_parent|
        stopping_parent == failing_parent ? false : original.call(stopping_parent)
      end

      service.call

      expect(Events::TextMessage.where(body: 'STOP')).to be_empty
      expect(child.reload).to have_attributes(should_contact_parent1: true, group_status: 'active')
    end
  end
end
