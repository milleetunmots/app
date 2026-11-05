require 'rails_helper'

RSpec.describe Group::CheckChosenModulesService do
  describe '#call' do
    subject(:service) { described_class.new(groups: [group]).call }

    let!(:group) { FactoryBot.create(:group, name: 'Printemps 2026') }
    let!(:support_module) { FactoryBot.create(:support_module) }

    def create_module(group: self.group, support_module: self.support_module, is_programmed: false)
      child = FactoryBot.create(:child, group: group, group_status: 'active')
      FactoryBot.create(:children_support_module, child: child, parent: child.parent1, support_module: support_module, is_programmed: is_programmed)
    end

    context 'quand chaque enfant actif a un module choisi non programmé' do
      before { create_module }

      it 'ne signale rien' do
        expect(service.errors).to be_empty
      end
    end

    context 'quand tous les modules choisis sont déjà programmés' do
      before { create_module(is_programmed: true) }

      it 'signale la cohorte' do
        expect(service.errors).to eq([{ message: "Les modules de la cohorte #{group.name} ont déjà été programmés", context: { group_id: group.id } }])
      end
    end

    context "quand un enfant actif n'a pas choisi de module" do
      before do
        create_module
        create_module(support_module: nil)
      end

      it 'signale la cohorte' do
        expect(service.errors).to eq([{ message: "Dans la cohorte #{group.name}, il y a des enfants sans choix de module.", context: { group_id: group.id } }])
      end
    end

    context "quand l'enfant sans choix n'est pas actif" do
      before do
        create_module
        create_module(support_module: nil).child.update_column(:group_status, 'paused')
      end

      it 'ne signale rien' do
        expect(service.errors).to be_empty
      end
    end

    context 'pour plusieurs cohortes en défaut' do
      subject(:service) { described_class.new(groups: [group, other_group]).call }

      let!(:other_group) { FactoryBot.create(:group, name: 'Automne 2026') }

      before do
        create_module(is_programmed: true)
        create_module(group: other_group)
        create_module(group: other_group, support_module: nil)
      end

      it 'signale chaque cohorte' do
        expect(service.errors.map { |error| error[:context][:group_id] }).to contain_exactly(group.id, other_group.id)
      end
    end
  end
end
