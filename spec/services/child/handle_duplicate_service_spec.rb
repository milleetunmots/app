require 'rails_helper'

RSpec.describe Child::HandleDuplicateService do
  subject { Child::HandleDuplicateService.new }

  before do
    stub_request(:post, "https://api.aircall.io/v1/contacts")
      .to_return(status: 200, body: '{"contact": {"id": 123}}', headers: {})
  end

  context "when many parents with the same phone number have differents children" do
    let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755802002')}
    let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755802002')}
    let!(:first_child) { FactoryBot.create(:child, parent1: first_parent) }
    let!(:second_child) { FactoryBot.create(:child, parent1: second_parent) }
    let!(:third_child) { FactoryBot.create(:child, parent1: second_parent) }
    let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }

    it "put all the children in the same sibling group" do
      first_child_support_id = first_child.child_support_id
      first_parent_id = first_parent.id

      subject.call

      expect(second_child.reload.child_support_id).to eq(first_child_support_id)
      expect(second_child.reload.parent1_id).to eq(first_parent_id)
      expect(third_child.reload.child_support_id).to eq(first_child_support_id)
      expect(third_child.reload.parent1_id).to eq(first_parent_id)
      expect(second_parent.reload.discarded?).to eq(true)
    end

    it "if a child is in an attributed group, add the others children to his siblings" do
      group.update!(supporters_assigned_at: Time.zone.now)
      second_child.group_id = group.id
      second_child.group_status = 'active'
      second_child.save!
      second_child_support_id = second_child.child_support_id
      second_parent_id = second_parent.id

      subject.call

      expect(first_child.reload.child_support_id).to eq(second_child_support_id)
      expect(first_child.reload.parent1_id).to eq(second_parent_id)
      expect(first_parent.reload.discarded?).to eq(true)
    end
  end

  context "when many parents with the same phone number have same children" do
    let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755800000')}
    let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755800000')}
    let!(:first_child) { FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent) }
    let!(:second_child) { FactoryBot.create(:child, first_name: 'Prenom ', last_name: ' Nom', birthdate: first_child.birthdate, parent1: second_parent) }

    it "discard the last children and their parents" do
      subject.call
      expect(second_child.reload.discarded?).to eq(true)
      expect(first_child.reload.discarded?).to eq(false)
      expect(second_parent.reload.discarded?).to eq(true)
      expect(first_parent.reload.discarded?).to eq(false)
    end
  end

  context "when many children with same firstname, lastname and phone number have differents parents" do
    let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755800000')}
    let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755800001')}
    let!(:first_child) { FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent) }
    let!(:second_child) { FactoryBot.create(:child, first_name: 'Prenom ', last_name: ' Nom', birthdate: first_child.birthdate, parent1: second_parent) }

    it "link the parents" do
      subject.call
      new_parents = [first_child.reload.parent1_id, first_child.reload.parent2_id]
      expect(new_parents).to include first_parent.id, second_parent.id
      expect(second_child.reload.discarded?).to eq(true)
    end
  end

  context "when two children with same firstname, lastname, parent1 and at least one of them don't have parent2" do
    let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755800001') }
    let!(:duplicated_parent) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:child_with_parent2) { FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent, parent2: second_parent) }
    let!(:child_without_parent2) { FactoryBot.create(:child, first_name: 'Prenom ', last_name: ' Nom', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent) }
    let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }

    context "if the two children don't have a group" do
      it "delete the child whithout parent2 and his parent1" do
        subject.call
        expect(child_without_parent2.reload.discarded?).to eq(true)
        expect(duplicated_parent.reload.discarded?).to eq(true)
      end
    end

    context "if the two children are in not active group" do
      it "delete the child whithout parent2 and his parent1" do
        child_with_parent2.update(group: group, group_status: 'active')
        child_without_parent2.update(group: group, group_status: 'active')

        subject.call
        expect(child_without_parent2.reload.discarded?).to eq(true)
        expect(duplicated_parent.reload.discarded?).to eq(true)
      end
    end

    context "if many not_active children have parent2" do
      let!(:duplicated_parent1) { FactoryBot.create(:parent, phone_number: '0755800000') }
      let!(:duplicated_parent2) { FactoryBot.create(:parent, phone_number: '0755800001') }
      let!(:duplicated_child_with_parent2) { FactoryBot.create(:child, first_name: ' Prenom ', last_name: ' Nom', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent1, parent2: duplicated_parent2) }
      it "keep the recent child and delete others" do

        subject.call
        expect(child_with_parent2.reload.discarded?).to eq(true)
        expect(child_without_parent2.reload.discarded?).to eq(true)
        expect(first_parent.reload.discarded?).to eq(true)
      end
    end

    context "if a child without parent2 is active in an attributed group" do
      let!(:duplicated_parent1) { FactoryBot.create(:parent, phone_number: '0755800000') }
      let!(:duplicated_parent2) { FactoryBot.create(:parent, phone_number: '0755800001') }
      let!(:duplicated_child_with_parent2) { FactoryBot.create(:child, first_name: ' Prenom ', last_name: ' Nom', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent1, parent2: duplicated_parent2) }
      it "add it parent2 and delete children without group" do
        group.update(supporters_assigned_at: Time.zone.now)
        child_without_parent2.update(group: group, group_status: 'active')


        subject.call
        expect(child_with_parent2.reload.discarded?).to eq(true)
        expect(first_parent.reload.discarded?).to eq(true)
        expect(child_without_parent2.reload.parent2).to be_present
      end
    end
  end

  context "when two children with same firstname, lastname, parent1 and parent2" do
    let!(:first_parent) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:second_parent) { FactoryBot.create(:parent, phone_number: '0755800001') }
    let!(:duplicated_first_parent) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:duplicated_second_parent) { FactoryBot.create(:parent, phone_number: '0755800001') }
    let!(:first_child) { FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent, parent2: second_parent) }
    let!(:duplicated_child) { FactoryBot.create(:child, first_name: 'Prenom ', last_name: ' Nom', birthdate: first_child.birthdate, parent1: duplicated_first_parent, parent2: duplicated_second_parent) }

    context "if the two children don't have a group" do
      it "delete the recent child, his parent1, parent2 and his child_support" do
        subject.call
        expect(duplicated_child.reload.discarded?).to eq(true)
        expect(duplicated_first_parent.reload.discarded?).to eq(true)
        expect(duplicated_second_parent.reload.discarded?).to eq(true)
        expect(duplicated_child.child_support.reload.discarded?).to eq(true)
      end
    end

    context "if at least one child is in an attributed group" do
      let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }
      it "keep children in an attributed group and delete others" do
        group.update(supporters_assigned_at: Time.zone.now)
        first_child.update(group: group, group_status: 'active')

        subject.call
        expect(duplicated_child.reload.discarded?).to eq(true)
        expect(duplicated_child.child_support.reload.discarded?).to eq(true)
        expect(duplicated_first_parent.reload.discarded?).to eq(true)
        expect(duplicated_second_parent.reload.discarded?).to eq(true)
      end
    end
  end

  context "when there are the same parents and differents children"do
    let!(:first_parent1) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:first_parent2) { FactoryBot.create(:parent, phone_number: '0755800001') }
    let!(:duplicated_first_parent1) { FactoryBot.create(:parent, phone_number: '0755800000') }
    let!(:duplicated_first_parent2) { FactoryBot.create(:parent, phone_number: '0755800001') }
    let!(:first_child) { FactoryBot.create(:child, first_name: 'preNom', last_name: 'nOm', parent1: first_parent1, parent2: first_parent2) }
    let!(:duplicated_first_child) { FactoryBot.create(:child, first_name: 'duplicate Prenom ', last_name: 'duplicate Nom', parent1: duplicated_first_parent1, parent2: duplicated_first_parent2) }
    let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }

    it "if at least one child is not active delete the recent parents and put all children in the same siblings group" do
      group.update(supporters_assigned_at: Time.zone.now)
      first_child.update(group: group, group_status: 'active')

      subject.call
      expect(duplicated_first_parent1.reload.discarded?).to eq(true)
      expect(duplicated_first_parent2.reload.discarded?).to eq(true)
      expect(duplicated_first_child.reload.parent1_id).to eq(first_parent1.id)
      expect(duplicated_first_child.reload.parent2_id).to eq(first_parent2.id)
    end
  end

  context "quand des doublons par nom et naissance ont un parent 2 et que l'un d'eux est dans une cohorte" do
    def create_child_and_duplicate_without_common_parent2
      parent1 = FactoryBot.create(:parent, phone_number: '0755810000')
      child = FactoryBot.create(:child, first_name: 'Léa', last_name: 'Martin', birthdate: Date.new(2027, 1, 10), parent1: parent1)
      duplicate_parent1 = FactoryBot.create(:parent, phone_number: '0755810000')
      duplicate_parent2 = FactoryBot.create(:parent, phone_number: '0755810001')
      duplicate = FactoryBot.create(:child, first_name: 'Léa', last_name: 'Martin', birthdate: Date.new(2027, 1, 10), parent1: duplicate_parent1, parent2: duplicate_parent2)
      [child, duplicate]
    end

    def create_child_with_both_parents(created_at:, first_parent_phone:, second_parent_phone:)
      travel_to(created_at) do
        parent1 = FactoryBot.create(:parent, phone_number: first_parent_phone)
        parent2 = FactoryBot.create(:parent, phone_number: second_parent_phone)
        FactoryBot.create(:child, first_name: 'Hugo', last_name: 'Petit', birthdate: Date.new(2026, 9, 5), parent1: parent1, parent2: parent2)
      end
    end

    [
      ['avant la date de fin de la cohorte', Date.new(2027, 11, 30), Time.zone.local(2027, 11, 28, 6)],
      ['après la date de fin de la cohorte', Date.new(2027, 11, 30), Time.zone.local(2027, 12, 5, 6)],
      ['longtemps après la date de fin de la cohorte', Date.new(2027, 11, 30), Time.zone.local(2029, 6, 3, 6)],
      ['dans une cohorte sans date de fin', nil, Time.zone.local(2028, 12, 3, 6)]
    ].each do |moment, ended_at, run_at|
      context "quand la cohorte est attribuée et que l'algorithme tourne #{moment}" do
        it "archive le doublon et ajoute le parent 2 à l'enfant de la cohorte" do
          child, duplicate = travel_to(Time.zone.local(2027, 5, 20, 10)) do
            child, duplicate = create_child_and_duplicate_without_common_parent2
            group = FactoryBot.create(:group, started_at: Date.new(2027, 5, 31), ended_at: ended_at, supporters_assigned_at: Time.zone.now)
            child.update!(group: group, group_status: 'active')
            [child, duplicate]
          end

          travel_to(run_at) { Child::HandleDuplicateService.new.call }

          expect(duplicate.reload).to be_discarded
          expect(child.reload).not_to be_discarded
          expect(child.parent2).to eq(duplicate.parent2)
        end
      end
    end

    context "quand la cohorte de l'enfant sans parent 2 n'est pas attribuée" do
      it "archive l'enfant de la cohorte et sa fiche, et garde le doublon avec sa propre fiche" do
        child, duplicate = travel_to(Time.zone.local(2027, 5, 20, 10)) do
          child, duplicate = create_child_and_duplicate_without_common_parent2
          group = FactoryBot.create(:group, started_at: Date.new(2027, 5, 31), ended_at: Date.new(2027, 11, 30))
          child.update!(group: group, group_status: 'active')
          [child, duplicate]
        end

        travel_to(Time.zone.local(2027, 5, 23, 6)) { Child::HandleDuplicateService.new.call }

        expect(child.reload).to be_discarded
        expect(child.child_support.reload).to be_discarded
        expect(duplicate.reload).not_to be_discarded
        expect(duplicate.child_support.reload).not_to be_discarded
      end
    end

    context "quand la cohorte est attribuée mais n'a pas encore démarré" do
      it "archive le doublon plus ancien et garde l'enfant de la cohorte avec son accompagnante" do
        supporter = FactoryBot.create(:admin_user, user_role: 'caller')
        duplicate = create_child_with_both_parents(created_at: Time.zone.local(2027, 1, 10, 10), first_parent_phone: '0755820000', second_parent_phone: '0755820001')
        child = create_child_with_both_parents(created_at: Time.zone.local(2027, 1, 15, 10), first_parent_phone: '0755820000', second_parent_phone: '0755820001')
        group = travel_to(Time.zone.local(2027, 2, 19, 10)) do
          group = FactoryBot.create(:group, started_at: Date.new(2027, 3, 1), supporters_assigned_at: Time.zone.now)
          child.update!(group: group, group_status: 'active')
          child.child_support.update!(supporter: supporter)
          group
        end
        child_support_id = child.child_support_id

        travel_to(Time.zone.local(2027, 2, 21, 6)) { Child::HandleDuplicateService.new.call }

        expect(duplicate.reload).to be_discarded
        expect(child.reload).not_to be_discarded
        expect(child).to have_attributes(group_id: group.id, group_status: 'active', child_support_id: child_support_id)
        expect(child.child_support.supporter).to eq(supporter)
      end
    end

    context "quand la cohorte a démarré sans date d'attribution" do
      it 'garde le plus ancien des doublons et archive le plus récent' do
        child = create_child_with_both_parents(created_at: Time.zone.local(2027, 1, 10, 10), first_parent_phone: '0755830000', second_parent_phone: '0755830001')
        duplicate = create_child_with_both_parents(created_at: Time.zone.local(2027, 1, 15, 10), first_parent_phone: '0755830000', second_parent_phone: '0755830001')
        travel_to(Time.zone.local(2027, 2, 19, 10)) do
          group = FactoryBot.create(:group, started_at: Date.new(2027, 3, 1))
          group.update!(support_module_programmed: 1)
          child.update!(group: group, group_status: 'active')
        end

        travel_to(Time.zone.local(2027, 3, 7, 6)) { Child::HandleDuplicateService.new.call }

        expect(duplicate.reload).to be_discarded
        expect(child.reload).not_to be_discarded
      end
    end
  end

  context 'quand deux doublons sans parent 2 sont chacun dans une cohorte attribuée différente' do
    it 'ne touche à aucun des deux et les laisse parmi les doublons potentiels' do
      child, duplicate = travel_to(Time.zone.local(2027, 2, 15, 10)) do
        child = FactoryBot.create(:child, first_name: 'Nina', last_name: 'Roux', birthdate: Date.new(2026, 9, 1), parent1: FactoryBot.create(:parent, phone_number: '0755840000'))
        duplicate = FactoryBot.create(:child, first_name: 'Nina', last_name: 'Roux', birthdate: Date.new(2026, 9, 1), parent1: FactoryBot.create(:parent, phone_number: '0755840001'))
        march_group = FactoryBot.create(:group, started_at: Date.new(2027, 3, 1), supporters_assigned_at: Time.zone.now)
        april_group = FactoryBot.create(:group, started_at: Date.new(2027, 4, 5), supporters_assigned_at: Time.zone.now)
        child.update!(group: march_group, group_status: 'active')
        duplicate.update!(group: april_group, group_status: 'active')
        [child, duplicate]
      end
      child_attributes = child.attributes.slice('group_id', 'group_status', 'child_support_id', 'parent1_id', 'parent2_id')
      duplicate_attributes = duplicate.attributes.slice('group_id', 'group_status', 'child_support_id', 'parent1_id', 'parent2_id')

      travel_to(Time.zone.local(2027, 2, 21, 6)) { Child::HandleDuplicateService.new.call }

      expect(child.reload).not_to be_discarded
      expect(duplicate.reload).not_to be_discarded
      expect(child).to have_attributes(child_attributes)
      expect(duplicate).to have_attributes(duplicate_attributes)
      expect(Child.potential_duplicates).to include(child, duplicate)
    end
  end

  context "quand le parent d'un enfant d'une cohorte attribuée partage son téléphone avec le parent d'un autre enfant" do
    it "ne rattache pas l'enfant de la cohorte attribuée à une autre fiche" do
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      protected_child, june_group = travel_to(Time.zone.local(2027, 4, 10, 10)) do
        other_child = FactoryBot.create(:child, first_name: 'Sara', last_name: 'Diallo', birthdate: Date.new(2026, 10, 1), parent1: FactoryBot.create(:parent, phone_number: '0755850000'))
        protected_child = FactoryBot.create(:child, first_name: 'Noé', last_name: 'Diallo', birthdate: Date.new(2026, 8, 1), parent1: FactoryBot.create(:parent, phone_number: '0755850000'))
        may_group = FactoryBot.create(:group, started_at: Date.new(2027, 5, 3))
        june_group = FactoryBot.create(:group, started_at: Date.new(2027, 6, 7), supporters_assigned_at: Time.zone.now)
        other_child.update!(group: may_group, group_status: 'active')
        protected_child.update!(group: june_group, group_status: 'active')
        protected_child.child_support.update!(supporter: supporter)
        [protected_child, june_group]
      end
      protected_child_attributes = protected_child.attributes.slice('child_support_id', 'parent1_id')

      travel_to(Time.zone.local(2027, 4, 18, 6)) { Child::HandleDuplicateService.new.call }

      expect(protected_child.reload).not_to be_discarded
      expect(protected_child).to have_attributes(protected_child_attributes.merge('group_id' => june_group.id, 'group_status' => 'active'))
      expect(protected_child.child_support.supporter).to eq(supporter)
    end
  end

  context "quand un enfant en attente partage le téléphone d'un parent avec un enfant d'une cohorte attribuée" do
    it 'le rattache à la fiche de cet enfant, toujours en attente, sans changer son accompagnante' do
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      sibling, group = travel_to(Time.zone.local(2027, 2, 15, 10)) do
        sibling = FactoryBot.create(:child, first_name: 'Inès', last_name: 'Leroy', birthdate: Date.new(2026, 10, 1), parent1: FactoryBot.create(:parent, phone_number: '0755860000'))
        group = FactoryBot.create(:group, started_at: Date.new(2027, 3, 1), supporters_assigned_at: Time.zone.local(2027, 2, 19, 10))
        sibling.update!(group: group, group_status: 'active')
        sibling.child_support.update!(supporter: supporter)
        [sibling, group]
      end
      waiting_child = travel_to(Time.zone.local(2027, 4, 10, 10)) do
        FactoryBot.create(:child, first_name: 'Sami', last_name: 'Leroy', birthdate: Date.new(2027, 1, 15), parent1: FactoryBot.create(:parent, phone_number: '0755860000'))
      end
      waiting_child_old_child_support = waiting_child.child_support

      travel_to(Time.zone.local(2027, 4, 18, 6)) { Child::HandleDuplicateService.new.call }

      expect(waiting_child.reload).to have_attributes(child_support_id: sibling.child_support_id, group_id: nil, group_status: 'waiting')
      expect(sibling.reload).to have_attributes(group_id: group.id, group_status: 'active')
      expect(sibling.child_support.supporter).to eq(supporter)
      expect(waiting_child_old_child_support.reload).to be_discarded
    end
  end

  context "quand un enfant d'une cohorte non attribuée est rattaché à la fiche de sa fratrie" do
    def create_siblings_and_link(sibling_group_attributes:, linked_child_birthdate:)
      sibling, linked_child = travel_to(Time.zone.local(2027, 4, 10, 10)) do
        sibling = FactoryBot.create(:child, first_name: 'Sara', last_name: 'Diallo', birthdate: Date.new(2025, 12, 1), parent1: FactoryBot.create(:parent, phone_number: '0755870000'))
        linked_child = FactoryBot.create(:child, first_name: 'Noé', last_name: 'Diallo', birthdate: linked_child_birthdate, parent1: FactoryBot.create(:parent, phone_number: '0755870000'))
        sibling_group = FactoryBot.create(:group, sibling_group_attributes)
        june_group = FactoryBot.create(:group, started_at: Date.new(2027, 6, 7))
        sibling.update!(group: sibling_group, group_status: 'active')
        linked_child.update!(group: june_group, group_status: 'active')
        [sibling, linked_child]
      end

      travel_to(Time.zone.local(2027, 4, 18, 6)) { Child::HandleDuplicateService.new.call }

      [sibling.reload, linked_child.reload]
    end

    [
      ['non attribuée, qui commence dans 15 jours', { started_at: Date.new(2027, 5, 3) }],
      ['attribuée, qui commence dans 15 jours', { started_at: Date.new(2027, 5, 3), supporters_assigned_at: Time.zone.local(2027, 4, 15, 10) }]
    ].each do |description, sibling_group_attributes|
      context "quand la cohorte de la fratrie est #{description}" do
        it 'fait rejoindre cette cohorte à un enfant qui aura 4 mois à son début' do
          sibling, linked_child = create_siblings_and_link(sibling_group_attributes: sibling_group_attributes, linked_child_birthdate: Date.new(2027, 1, 3))

          expect(linked_child).to have_attributes(child_support_id: sibling.child_support_id, group_id: sibling.group_id, group_status: 'active')
        end

        it "laisse en attente, sans cohorte, un enfant qui n'aura pas 4 mois à son début" do
          sibling, linked_child = create_siblings_and_link(sibling_group_attributes: sibling_group_attributes, linked_child_birthdate: Date.new(2027, 1, 4))

          expect(linked_child).to have_attributes(child_support_id: sibling.child_support_id, group_id: nil, group_status: 'waiting')
        end
      end
    end

    [
      ['non attribuée, qui a commencé', { started_at: Date.new(2027, 4, 5) }],
      ['attribuée, qui a commencé', { started_at: Date.new(2027, 4, 5), supporters_assigned_at: Time.zone.local(2027, 3, 20, 10) }],
      ['attribuée et terminée', { started_at: Date.new(2026, 4, 6), ended_at: Date.new(2027, 3, 1), supporters_assigned_at: Time.zone.local(2026, 3, 20, 10) }]
    ].each do |description, sibling_group_attributes|
      context "quand la cohorte de la fratrie est #{description}" do
        it "laisse l'enfant en attente, sans cohorte" do
          sibling, linked_child = create_siblings_and_link(sibling_group_attributes: sibling_group_attributes, linked_child_birthdate: Date.new(2026, 10, 1))

          expect(linked_child).to have_attributes(child_support_id: sibling.child_support_id, group_id: nil, group_status: 'waiting')
        end
      end
    end
  end
end
