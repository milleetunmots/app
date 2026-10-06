require 'rails_helper'

RSpec.describe ChildrenSupportModule::SaveBookFromSupportModuleService do
  let!(:group) { FactoryBot.create(:group) }
  let!(:book) { FactoryBot.create(:book) }
  let!(:support_module) { FactoryBot.create(:support_module, book: book) }

  subject(:service) { described_class.new(group_id: group.id) }

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
