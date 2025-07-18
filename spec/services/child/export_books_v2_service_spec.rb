require 'rails_helper'

RSpec.describe Child::ExportBooksV2Service do
  describe '#find_children_lists' do
    let_it_be(:group) { FactoryBot.create(:group) }
    let_it_be(:book1) { FactoryBot.create(:book, title: 'Book 1', ean: '1234567890123') }
    let_it_be(:book2) { FactoryBot.create(:book, title: 'Book 2', ean: '9876543210987') }
    let_it_be(:support_module1) { FactoryBot.create(:support_module, book: book1) }
    let_it_be(:support_module2) { FactoryBot.create(:support_module, book: book2) }

    let_it_be(:child1) { FactoryBot.create(:child, group: group, group_status: 'active') }
    let_it_be(:child2) { FactoryBot.create(:child, group: group, group_status: 'active') }
    let_it_be(:child3) { FactoryBot.create(:child, group: group, group_status: 'active') }
    let_it_be(:inactive_child) { FactoryBot.create(:child, group: group, group_status: 'stopped') }

    let_it_be(:children_support_module1) do
      FactoryBot.create(:children_support_module, child: child1, parent: child1.parent1, support_module: support_module1)
    end

    let_it_be(:children_support_module2) do
      FactoryBot.create(:children_support_module, child: child2, parent: child2.parent1, support_module: support_module2)
    end

    let_it_be(:children_support_module3) do
      FactoryBot.create(:children_support_module, child: child3, parent: child3.parent1, support_module: support_module2)
    end

    context 'when group_ids are provided' do
      let(:service) { Child::ExportBooksV2Service.new(group_ids: [group.id]) }

      it 'returns children sorted by support module books' do
        children_list = service.send(:find_children_lists)

        expect(children_list.keys.count).to eq(2)

        book1_key = "#{book1.ean} #{book1.title} #{Time.zone.now.strftime('%d-%m-%Y')}"
        book2_key = "#{book2.ean} #{book2.title} #{Time.zone.now.strftime('%d-%m-%Y')}"

        expect(children_list[book1_key]).to match_array([child1])
        expect(children_list[book2_key]).to match_array([child2, child3])
      end

      it 'excludes inactive children' do
        children_list = service.send(:find_children_lists)

        all_children = children_list.values.flatten
        expect(all_children).not_to include(inactive_child)
      end
    end

    context 'when no children are found' do
      let(:service) { Child::ExportBooksV2Service.new(group_ids: [-1]) }

      it 'returns an empty hash' do
        children_list = service.send(:find_children_lists)
        expect(children_list).to be_empty
      end
    end

    describe '#call' do
      let(:service) { Child::ExportBooksV2Service.new(group_ids: [group.id]) }

      it 'creates a zip file when children are found' do
        result = service.call

        expect(result.errors).to be_empty
        expect(result.zip_file).to be_kind_of(Tempfile)
      end

      context 'when no children are found' do
        let(:service) { described_class.new(group_ids: [-1]) }

        it 'adds an error message' do
          result = service.call

          expect(result.errors).to include('Aucun choix de module à programmer n\'a été trouvé')
          expect(result.zip_file).to be_nil
        end
      end
    end
  end
end
