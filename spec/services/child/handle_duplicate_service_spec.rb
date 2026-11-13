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

    it "if a child is in active group, add the others children to his siblings" do
      group.started_at = 2.months.ago.beginning_of_week
      group.save!
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

    context "if a child without parent2 is active" do
      let!(:duplicated_parent1) { FactoryBot.create(:parent, phone_number: '0755800000') }
      let!(:duplicated_parent2) { FactoryBot.create(:parent, phone_number: '0755800001') }
      let!(:duplicated_child_with_parent2) { FactoryBot.create(:child, first_name: ' Prenom ', last_name: ' Nom', birthdate: child_with_parent2.birthdate, parent1: duplicated_parent1, parent2: duplicated_parent2) }
      it "add it parent2 and delete children without group" do
        group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
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

    context "if at least one child is in started group" do
      let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }
      it "keep children in a started group and delete others" do
        group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
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
      group.update(started_at: Time.zone.now.prev_occurring(:monday), support_module_programmed: 1)
      first_child.update(group: group, group_status: 'active')

      subject.call
      expect(duplicated_first_parent1.reload.discarded?).to eq(true)
      expect(duplicated_first_parent2.reload.discarded?).to eq(true)
      expect(duplicated_first_child.reload.parent1_id).to eq(first_parent1.id)
      expect(duplicated_first_child.reload.parent2_id).to eq(first_parent2.id)
    end
  end

  context "quand un nouvel enfant est inscrit avec le numéro d'un parent dont la fiche est suivie par une accompagnante" do
    it "rattache le nouvel enfant à la fiche suivie sans changer le nombre de fiches de l'accompagnante" do
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      group = FactoryBot.create(:group, expected_children_number: 0)
      sister = FactoryBot.create(:child, first_name: 'Inès', last_name: 'Martin', group: group, group_status: 'active',
                                         parent1: FactoryBot.create(:parent, phone_number: '0611111111'))
      sister.child_support.update!(supporter: supporter)
      new_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin',
                                            parent1: FactoryBot.create(:parent, phone_number: '0611111111'))

      Child::HandleDuplicateService.new.call

      expect(new_child.reload.child_support).to eq(sister.child_support)
      expect(ChildSupport.kept.where(supporter: supporter)).to contain_exactly(sister.child_support)
    end
  end

  context "quand le traitement d'un groupe de doublons retire une fiche suivie" do
    it 'annule le traitement du groupe et le signale à Rollbar' do
      allow(Rollbar).to receive(:warning)
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      group = FactoryBot.create(:group, expected_children_number: 0)
      sister = FactoryBot.create(:child, first_name: 'Inès', last_name: 'Martin', group: group, group_status: 'active',
                                         parent1: FactoryBot.create(:parent, phone_number: '0611111111'))
      sister.child_support.update!(supporter: supporter)
      new_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin',
                                            parent1: FactoryBot.create(:parent, phone_number: '0611111111'))
      service = Child::HandleDuplicateService.new
      allow(service).to receive(:move_children_to_a_single_child_support) { sister.child_support.discard }

      service.call

      expect(sister.child_support.reload).to be_kept
      expect(Rollbar).to have_received(:warning).with(a_string_including('fiche suivie'), child_ids: contain_exactly(sister.id, new_child.id))
    end
  end

  context "quand un enfant suivi a un nouveau doublon dont la fiche n'a pas d'accompagnante" do
    it "archive le nouveau doublon et garde l'enfant suivi avec sa fiche" do
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      birthdate = Time.zone.today - 10.months
      group = FactoryBot.create(:group, expected_children_number: 0)
      supported_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate, group: group, group_status: 'active',
                                                  parent1: FactoryBot.create(:parent, phone_number: '0611111111'),
                                                  parent2: FactoryBot.create(:parent, phone_number: '0622222222'))
      supported_child.child_support.update!(supporter: supporter)
      duplicate = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate,
                                            parent1: FactoryBot.create(:parent, phone_number: '0611111111'),
                                            parent2: FactoryBot.create(:parent, phone_number: '0622222222'))

      Child::HandleDuplicateService.new.call

      expect(duplicate.reload).to be_discarded
      expect(supported_child.reload).to be_kept
      expect(supported_child.child_support).to be_kept
      expect(supported_child.child_support.supporter).to eq(supporter)
    end
  end

  context "quand les fiches des deux doublons sont suivies par une accompagnante" do
    it "n'archive aucun des deux enfants" do
      first_supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      second_supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      birthdate = Time.zone.today - 10.months
      group = FactoryBot.create(:group, expected_children_number: 0)
      first_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate, group: group, group_status: 'active', created_at: 1.month.ago,
                                              parent1: FactoryBot.create(:parent, phone_number: '0611111111'),
                                              parent2: FactoryBot.create(:parent, phone_number: '0622222222'))
      first_child.child_support.update!(supporter: first_supporter)
      second_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate, group: group, group_status: 'active', created_at: 2.weeks.ago,
                                               parent1: FactoryBot.create(:parent, phone_number: '0611111111'),
                                               parent2: FactoryBot.create(:parent, phone_number: '0622222222'))
      second_child.child_support.update!(supporter: second_supporter)

      Child::HandleDuplicateService.new.call

      expect(first_child.reload).to be_kept
      expect(second_child.reload).to be_kept
      expect(first_child.child_support).to be_kept
      expect(second_child.child_support).to be_kept
    end
  end

  context "quand un ancien enfant suivi est réinscrit par son autre parent" do
    it "garde l'ancien enfant et sa fiche, lui ajoute l'autre parent et archive la réinscription" do
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      birthdate = Time.zone.today - 22.months
      group = FactoryBot.create(:group, expected_children_number: 0, started_at: Date.new(2025, 1, 6), ended_at: Date.new(2025, 6, 30))
      old_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate, group: group, group_status: 'stopped',
                                            parent1: FactoryBot.create(:parent, phone_number: '0611111111'))
      old_child.child_support.update!(supporter: supporter)
      father = FactoryBot.create(:parent, phone_number: '0622222222')
      reenrollment = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate, parent1: father)

      Child::HandleDuplicateService.new.call

      expect(old_child.reload).to be_kept
      expect(old_child.group_status).to eq('stopped')
      expect(old_child.group).to eq(group)
      expect(old_child.parent2).to eq(father)
      expect(old_child.child_support).to be_kept
      expect(reenrollment.reload).to be_discarded
    end
  end

  context "quand un nouvel enfant inscrit avant sa sœur suivie partage le numéro de leur mère" do
    it "rattache le nouvel enfant à la fiche suivie plutôt que l'inverse" do
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      group = FactoryBot.create(:group, expected_children_number: 0)
      new_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin',
                                            parent1: FactoryBot.create(:parent, phone_number: '0611111111'))
      sister = FactoryBot.create(:child, first_name: 'Inès', last_name: 'Martin', group: group, group_status: 'active',
                                         parent1: FactoryBot.create(:parent, phone_number: '0611111111'))
      sister.child_support.update!(supporter: supporter)

      Child::HandleDuplicateService.new.call

      expect(new_child.reload.child_support).to eq(sister.child_support)
      expect(sister.reload.child_support).to be_kept
      expect(sister.child_support.supporter).to eq(supporter)
    end
  end

  context "quand deux fiches de parents au même numéro portent le même enfant et que la plus récente est suivie" do
    it "garde la famille suivie et archive l'autre" do
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      birthdate = Time.zone.today - 10.months
      group = FactoryBot.create(:group, expected_children_number: 0)
      duplicate = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate,
                                            parent1: FactoryBot.create(:parent, phone_number: '0611111111'))
      supported_parent = FactoryBot.create(:parent, phone_number: '0611111111')
      supported_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate, group: group, group_status: 'active', parent1: supported_parent)
      supported_child.child_support.update!(supporter: supporter)

      Child::HandleDuplicateService.new.call

      expect(duplicate.reload).to be_discarded
      expect(supported_child.reload).to be_kept
      expect(supported_child.parent1).to eq(supported_parent)
      expect(supported_parent.reload).to be_kept
      expect(supported_child.child_support).to be_kept
    end
  end

  context "quand deux enfants différents ont les mêmes parents et que le plus récent est suivi" do
    it "rattache l'autre enfant à la fiche suivie" do
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      group = FactoryBot.create(:group, expected_children_number: 0)
      sister = FactoryBot.create(:child, first_name: 'Inès', last_name: 'Martin', created_at: 1.month.ago,
                                         parent1: FactoryBot.create(:parent, phone_number: '0611111111'),
                                         parent2: FactoryBot.create(:parent, phone_number: '0622222222'))
      supported_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', group: group, group_status: 'active', created_at: 2.weeks.ago,
                                                  parent1: FactoryBot.create(:parent, phone_number: '0611111111'),
                                                  parent2: FactoryBot.create(:parent, phone_number: '0622222222'))
      supported_child.child_support.update!(supporter: supporter)

      Child::HandleDuplicateService.new.call

      expect(sister.reload.child_support).to eq(supported_child.child_support)
      expect(supported_child.reload.child_support).to be_kept
      expect(supported_child.child_support.supporter).to eq(supporter)
    end
  end

  context "quand deux doublons ont les mêmes parents et que le plus récent est suivi" do
    it "garde l'enfant suivi et archive le plus ancien" do
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      birthdate = Time.zone.today - 10.months
      group = FactoryBot.create(:group, expected_children_number: 0)
      older_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate, created_at: 1.month.ago,
                                              parent1: FactoryBot.create(:parent, phone_number: '0611111111'),
                                              parent2: FactoryBot.create(:parent, phone_number: '0622222222'))
      supported_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate, group: group, group_status: 'active', created_at: 2.weeks.ago,
                                                  parent1: FactoryBot.create(:parent, phone_number: '0611111111'),
                                                  parent2: FactoryBot.create(:parent, phone_number: '0622222222'))
      supported_child.child_support.update!(supporter: supporter)

      Child::HandleDuplicateService.new.call

      expect(older_child.reload).to be_discarded
      expect(supported_child.reload).to be_kept
      expect(supported_child.child_support).to be_kept
    end
  end

  context "quand l'enfant suivi n'a pas de parent 2 et que son doublon en a un" do
    it "garde l'enfant suivi, lui ajoute le parent 2 et archive le doublon" do
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      birthdate = Time.zone.today - 10.months
      group = FactoryBot.create(:group, expected_children_number: 0)
      supported_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate, group: group, group_status: 'active',
                                                  parent1: FactoryBot.create(:parent, phone_number: '0611111111'))
      supported_child.child_support.update!(supporter: supporter)
      father = FactoryBot.create(:parent, phone_number: '0622222222')
      duplicate = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate,
                                            parent1: FactoryBot.create(:parent, phone_number: '0611111111'), parent2: father)

      Child::HandleDuplicateService.new.call

      expect(duplicate.reload).to be_discarded
      expect(supported_child.reload).to be_kept
      expect(supported_child.parent2).to eq(father)
      expect(supported_child.child_support).to be_kept
    end
  end

  context "le jour du démarrage d'une cohorte dont aucun module n'est programmé" do
    it "ajoute le second parent à l'enfant suivi et archive le doublon" do
      supporter = FactoryBot.create(:admin_user, user_role: 'caller')
      start_day = Time.zone.today.next_occurring(:monday)
      travel_to start_day do
        birthdate = Time.zone.today - 10.months
        group = FactoryBot.create(:group, expected_children_number: 0, started_at: start_day, support_module_programmed: 0)
        supported_child = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate, group: group, group_status: 'active',
                                                    parent1: FactoryBot.create(:parent, phone_number: '0611111111'))
        supported_child.child_support.update!(supporter: supporter)
        father = FactoryBot.create(:parent, phone_number: '0622222222')
        duplicate = FactoryBot.create(:child, first_name: 'Léo', last_name: 'Martin', birthdate: birthdate, parent1: father)

        Child::HandleDuplicateService.new.call

        expect(supported_child.reload).to be_kept
        expect(supported_child.parent2).to eq(father)
        expect(supported_child.child_support.supporter).to eq(supporter)
        expect(duplicate.reload).to be_discarded
      end
    end
  end
end
