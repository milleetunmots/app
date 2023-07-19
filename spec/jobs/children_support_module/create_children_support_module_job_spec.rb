require 'rails_helper'

RSpec.describe ChildrenSupportModule::CreateChildrenSupportModuleJob, type: :job do

  subject { described_class }

  let(:group) { FactoryBot.create(:group) }

  describe '#perform_later' do
    it 'enqueues the job' do
      ActiveJob::Base.queue_adapter = :test
      expect {
        subject.perform_later(group.id)
      }.to have_enqueued_job(described_class).on_queue('default').exactly(:once)
    end
  end

  describe '#perform_now' do
    context 'two children with one parent each' do
      let!(:child1) { FactoryBot.create(:child, group: group, group_status: 'active') }
      let!(:child2) { FactoryBot.create(:child, group: group, group_status: 'active') }

      before do
        child1.child_support.update!(parent1_available_support_module_list: [1, 2, 3])
      end

      context 'with no children_support_modules' do
        it 'creates one children_support_module for each child and it\'s parent' do
          expect {
            subject.perform_now(group.id)
          }.to change { ChildrenSupportModule.count }.by(2)

          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent1.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent1.id).count).to eq(1)

          csm_1 = ChildrenSupportModule.find_by(child_id: child1.id, parent_id: child1.parent1.id)
          expect(csm_1.available_support_module_list).to eq(child1.child_support.parent1_available_support_module_list)
        end
      end

      context 'with one child_support_module already programmed' do
        let!(:csm_1) { FactoryBot.create(:children_support_module, child: child1, parent: child1.parent1, is_programmed: true) }

        it 'creates one children_support_module for each child and it\'s parent' do
          expect {
            subject.perform_now(group.id)
          }.to change { ChildrenSupportModule.count }.by(2)

          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent1.id).count).to eq(2)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent1.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent1.id, is_programmed: false).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent1.id, is_programmed: false).count).to eq(1)

          csm = ChildrenSupportModule.find_by(child_id: child1.id, parent_id: child1.parent1.id, is_programmed: false)
          expect(csm.available_support_module_list).to eq(child1.child_support.parent1_available_support_module_list)
        end
      end

      context 'with one child_support_module not programmed' do
        let!(:csm_1) { FactoryBot.create(:children_support_module, child: child1, parent: child1.parent1, is_programmed: false) }
        let!(:csm_2) { FactoryBot.create(:children_support_module, child: child2, parent: child2.parent1, is_programmed: true) }

        it 'creates one children_support_module only for child that has no children_support_module already programmed' do
          expect {
            subject.perform_now(group.id) rescue nil
          }.to change { ChildrenSupportModule.count }.by(1)

          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent1.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent1.id).count).to eq(2)
          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent1.id, is_programmed: false).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent1.id, is_programmed: false).count).to eq(1)
        end

        it { expect { subject.perform_now(group_id) }.to raise_error }
      end
    end

    context 'two children with two parents each' do
      let!(:child1) { FactoryBot.create(:child, group: group, group_status: 'active', parent2: FactoryBot.create(:parent)) }
      let!(:child2) { FactoryBot.create(:child, group: group, group_status: 'active', parent2: FactoryBot.create(:parent)) }

      before do
        child1.child_support.update!(
          parent1_available_support_module_list: [1, 2, 3],
          parent2_available_support_module_list: [4, 5, 6]
        )
      end

      context 'with no children_support_modules' do
        it 'creates one children_support_module for each child and it\'s parent' do
          expect {
            subject.perform_now(group.id)
          }.to change { ChildrenSupportModule.count }.by(4)

          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent1.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent2.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent1.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent2.id).count).to eq(1)

          csm_1 = ChildrenSupportModule.find_by(child_id: child1.id, parent_id: child1.parent1.id)
          csm_2 = ChildrenSupportModule.find_by(child_id: child1.id, parent_id: child1.parent2.id)
          expect(csm_1.available_support_module_list).to eq(child1.child_support.parent1_available_support_module_list)
          expect(csm_2.available_support_module_list).to eq(child1.child_support.parent2_available_support_module_list)
        end
      end

      context 'with one child_support_module already programmed' do
        let!(:csm_1) { FactoryBot.create(:children_support_module, child: child1, parent: child1.parent1, is_programmed: true) }

        it 'creates one children_support_module for each child and it\'s parent' do
          expect {
            subject.perform_now(group.id)
          }.to change { ChildrenSupportModule.count }.by(4)

          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent1.id).count).to eq(2)
          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent2.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent1.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent2.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent1.id, is_programmed: false).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent1.id, is_programmed: false).count).to eq(1)

          csm = ChildrenSupportModule.find_by(child_id: child1.id, parent_id: child1.parent1.id, is_programmed: false)
          expect(csm.available_support_module_list).to eq(child1.child_support.parent1_available_support_module_list)
        end
      end

      context 'with one child_support_module not programmed' do
        let!(:csm_1) { FactoryBot.create(:children_support_module, child: child1, parent: child1.parent1, is_programmed: false) }
        let!(:csm_1_parent_2) { FactoryBot.create(:children_support_module, child: child1, parent: child1.parent2, is_programmed: false) }
        let!(:csm_2) { FactoryBot.create(:children_support_module, child: child2, parent: child2.parent1, is_programmed: true) }

        it 'creates one children_support_module only for child that has no children_support_module already programmed' do
          expect {
            subject.perform_now(group.id) rescue nil
          }.to change { ChildrenSupportModule.count }.by(2)

          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent1.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent2.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent1.id).count).to eq(2)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent2.id).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent1.id, is_programmed: false).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent2.id, is_programmed: false).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent1.id, is_programmed: false).count).to eq(1)
          expect(ChildrenSupportModule.where(child_id: child2.id, parent_id: child2.parent2.id, is_programmed: false).count).to eq(1)
        end

        it { expect { subject.perform_now(group_id) }.to raise_error }
      end
    end

    context 'without child_support' do
      let!(:child1) { FactoryBot.create(:child, group: group, group_status: 'active') }

      before do
        child1.update_columns(child_support_id: nil)
      end

      it 'creates one children_support_module for each child and it\'s parent' do
        expect {
          subject.perform_now(group.id)
        }.to change { ChildrenSupportModule.count }.by(1)

        expect(ChildrenSupportModule.where(child_id: child1.id, parent_id: child1.parent1.id).count).to eq(1)

        csm_1 = ChildrenSupportModule.find_by(child_id: child1.id, parent_id: child1.parent1.id)
        expect(csm_1.available_support_module_list).to be_nil
      end
    end
  end
end
