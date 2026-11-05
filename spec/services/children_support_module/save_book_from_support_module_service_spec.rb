require 'rails_helper'

RSpec.describe ChildrenSupportModule::SaveBookFromSupportModuleService do
  let!(:group) { FactoryBot.create(:group) }
  let!(:book) { FactoryBot.create(:book) }
  let!(:support_module) { FactoryBot.create(:support_module, book: book) }

  subject(:service) { described_class.new(group_ids: [group.id]) }

  # le statut est posé après la création : la validation exige une cohorte
  # pour certains statuts, et l'inscription peut le recalculer
  def create_child_with_choice(group_status: 'active')
    child = FactoryBot.create(:child, group: group, group_status: 'active')
    child.update_column(:group_status, group_status)
    FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: support_module)
  end

  context "pour un enfant actif dont l'adresse n'est pas suspecte" do
    let!(:children_support_module) { create_child_with_choice }

    it 'enregistre le livre sans condition' do
      service.call

      expect(children_support_module.reload.book_id).to eq(book.id)
      expect(children_support_module.book_condition).to be_nil
    end
  end

  context "pour un enfant actif dont l'adresse est suspecte" do
    let!(:children_support_module) { create_child_with_choice }
    let!(:flagged_at) { 3.days.ago.change(usec: 0) }

    before { children_support_module.child.child_support.update_column(:address_suspected_invalid_at, flagged_at) }

    it 'enregistre le livre et le déclare « Non envoyé »' do
      freeze_time do
        service.call

        expect(children_support_module.reload.book_id).to eq(book.id)
        expect(children_support_module.book_condition).to eq('not_sent')
        expect(children_support_module.book_condition_changed_at).to eq(Time.zone.now)
      end
    end

    it "laisse la date de l'adresse suspecte inchangée" do
      service.call

      expect(children_support_module.child.child_support.reload.address_suspected_invalid_at).to eq(flagged_at)
    end
  end

  %w[paused stopped disengaged].each do |group_status|
    context "pour un enfant #{group_status}" do
      let!(:children_support_module) { create_child_with_choice(group_status: group_status) }

      it 'enregistre le livre et le déclare « Non envoyé »' do
        service.call

        expect(children_support_module.reload.book_id).to eq(book.id)
        expect(children_support_module.book_condition).to eq('not_sent')
      end

      # son adresse est correcte : la marquer suspecte serait un faux positif
      it "ne marque pas l'adresse suspecte" do
        service.call

        expect(children_support_module.child.child_support.reload.address_suspected_invalid_at).to be_nil
      end
    end
  end

  %w[not_supported waiting].each do |group_status|
    context "pour un enfant #{group_status}" do
      let!(:children_support_module) { create_child_with_choice(group_status: group_status) }

      it "n'enregistre ni livre ni condition" do
        service.call

        expect(children_support_module.reload.book_id).to be_nil
        expect(children_support_module.book_condition).to be_nil
      end
    end
  end

  # les CSM des enfants inactifs ne sont jamais programmés et repassent à chaque module
  context 'lors d’un second passage' do
    let!(:children_support_module) { create_child_with_choice(group_status: 'stopped') }

    it 'ne modifie ni le livre ni la date du statut « Non envoyé »' do
      travel_to(2.weeks.ago) { service.call }
      first_changed_at = children_support_module.reload.book_condition_changed_at
      support_module.update!(book: FactoryBot.create(:book))

      service.call

      expect(children_support_module.reload.book_id).to eq(book.id)
      expect(children_support_module.book_condition_changed_at).to eq(first_changed_at)
    end
  end

  context 'quand le livre non expédiable a déjà une condition' do
    let!(:children_support_module) { create_child_with_choice(group_status: 'stopped') }

    before { children_support_module.update_columns(book_condition: 'not_received', book_condition_changed_at: 1.day.ago) }

    it "n'écrase pas la condition existante" do
      service.call

      expect(children_support_module.reload.book_condition).to eq('not_received')
    end
  end

  context 'quand la condition a été vidée depuis la fiche' do
    let!(:children_support_module) { create_child_with_choice(group_status: 'stopped') }

    before { children_support_module.update_column(:book_condition, '') }

    it 'déclare le livre « Non envoyé »' do
      service.call

      expect(children_support_module.reload.book_condition).to eq('not_sent')
    end
  end

  context "quand le module choisi n'a pas de livre" do
    let!(:support_module) { FactoryBot.create(:support_module) }
    let!(:shippable_module) { create_child_with_choice }
    let!(:unshippable_module) { create_child_with_choice(group_status: 'stopped') }

    it "n'enregistre ni livre ni condition" do
      service.call

      expect(shippable_module.reload.book_id).to be_nil
      expect(unshippable_module.reload.book_id).to be_nil
      expect(unshippable_module.book_condition).to be_nil
    end
  end

  context 'quand le livre est déjà enregistré' do
    let!(:children_support_module) { create_child_with_choice }

    it 'ne le remplace pas par le livre actuel du module' do
      service.call
      support_module.update!(book: FactoryBot.create(:book))

      service.call

      expect(children_support_module.reload.book_id).to eq(book.id)
    end
  end

  # une relance de l'export ou deux exécutions simultanées travaillent sur une liste lue avant l'écriture
  context 'avec une liste de modules lue avant un premier enregistrement' do
    let!(:children_support_module) { create_child_with_choice }
    let!(:stale_modules) { ChildrenSupportModule.chosen_modules_for_group([group.id], include_unshippable: true) }

    before { described_class.new(group_ids: [group.id]).call }

    it 'ne remplace pas le livre enregistré' do
      support_module.update!(book: FactoryBot.create(:book))

      described_class.new(group_ids: [group.id], children_support_modules: stale_modules).call

      expect(children_support_module.reload.book_id).to eq(book.id)
    end

    it 'ne déclare pas « Non envoyé » un livre enregistré comme expédiable' do
      stale_modules.first.child.child_support.address_suspected_invalid_at = Time.zone.now

      described_class.new(group_ids: [group.id], children_support_modules: stale_modules).call

      expect(children_support_module.reload.book_condition).to be_nil
    end
  end

  # l'export fige à partir des modules qui ont servi à construire les fichiers
  context 'avec une liste de modules fournie' do
    let!(:children_support_module) { create_child_with_choice }
    let!(:modules) { ChildrenSupportModule.chosen_modules_for_group([group.id], include_unshippable: true) }

    it "s'appuie sur cette liste plutôt que sur l'état actuel de l'adresse" do
      children_support_module.child.child_support.update_column(:address_suspected_invalid_at, Time.zone.now)

      described_class.new(group_ids: [group.id], children_support_modules: modules).call

      expect(children_support_module.reload.book_id).to eq(book.id)
      expect(children_support_module.book_condition).to be_nil
    end
  end

  context 'pour un module déjà programmé' do
    let!(:children_support_module) { create_child_with_choice }

    before { children_support_module.update_column(:is_programmed, true) }

    it "n'enregistre pas de livre" do
      service.call

      expect(children_support_module.reload.book_id).to be_nil
    end
  end

  context 'pour plusieurs cohortes' do
    let!(:other_group) { FactoryBot.create(:group) }
    let!(:children_support_module) { create_child_with_choice }
    let!(:other_module) do
      child = FactoryBot.create(:child, group: other_group, group_status: 'active')
      FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: support_module)
    end

    it 'enregistre le livre dans chacune' do
      described_class.new(group_ids: [group.id, other_group.id]).call

      expect(children_support_module.reload.book_id).to eq(book.id)
      expect(other_module.reload.book_id).to eq(book.id)
    end
  end

  context 'pour le choix du parent 2' do
    let!(:child) do
      FactoryBot.create(:child, group: group, group_status: 'active', parent2: FactoryBot.create(:parent))
                .tap { |c| c.update_column(:group_status, 'stopped') }
    end
    let!(:parent2_module) do
      FactoryBot.create(:children_support_module, child: child, parent: child.parent2, support_module: support_module)
    end

    it "n'enregistre ni livre ni condition" do
      service.call

      expect(parent2_module.reload.book_id).to be_nil
      expect(parent2_module.book_condition).to be_nil
    end
  end
end
