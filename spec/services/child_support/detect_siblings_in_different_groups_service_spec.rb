require 'rails_helper'

RSpec.describe ChildSupport::DetectSiblingsInDifferentGroupsService do
  let!(:operation_project_manager) { FactoryBot.create(:admin_user, email: ENV['OPERATION_PROJECT_MANAGER_EMAIL']) }

  let!(:group_a) { FactoryBot.create(:group) }
  let!(:group_b) { FactoryBot.create(:group) }

  describe '#call' do
    subject { described_class.new.call }

    context 'when active siblings of a same fiche de suivi are in different cohorts' do
      let!(:sibling1) { FactoryBot.create(:child, group: group_a, group_status: 'active') }
      let!(:sibling2) do
        FactoryBot.create(
          :child,
          parent1: sibling1.parent1,
          child_support: sibling1.child_support,
          group: group_b,
          group_status: 'active',
          birthdate: sibling1.birthdate + 2.days
        )
      end

      it 'creates a single task listing the affected fiche de suivi' do
        expect { subject }.to change(Task, :count).by(1)

        task = Task.last
        expect(task.assignee).to eq(operation_project_manager)
        expect(task.description).to include(
          Rails.application.routes.url_helpers.edit_admin_child_support_url(id: sibling1.child_support.id)
        )
      end
    end

    context 'when active siblings of a same fiche de suivi are in the same cohort' do
      let!(:sibling1) { FactoryBot.create(:child, group: group_a, group_status: 'active') }
      let!(:sibling2) do
        FactoryBot.create(
          :child,
          parent1: sibling1.parent1,
          child_support: sibling1.child_support,
          group: group_a,
          group_status: 'active',
          birthdate: sibling1.birthdate + 2.days
        )
      end

      it 'does not create a task' do
        expect { subject }.not_to change(Task, :count)
      end
    end

    context 'when only one sibling is active' do
      let!(:active_sibling) { FactoryBot.create(:child, group: group_a, group_status: 'active') }
      let!(:stopped_sibling) do
        FactoryBot.create(
          :child,
          parent1: active_sibling.parent1,
          child_support: active_sibling.child_support,
          group: group_b,
          group_status: 'stopped',
          birthdate: active_sibling.birthdate + 2.days
        )
      end

      it 'does not create a task' do
        expect { subject }.not_to change(Task, :count)
      end
    end

    context 'when the fiche de suivi is discarded' do
      let!(:sibling1) { FactoryBot.create(:child, group: group_a, group_status: 'active') }
      let!(:sibling2) do
        FactoryBot.create(
          :child,
          parent1: sibling1.parent1,
          child_support: sibling1.child_support,
          group: group_b,
          group_status: 'active',
          birthdate: sibling1.birthdate + 2.days
        )
      end

      before { sibling1.child_support.discard }

      it 'does not create a task' do
        expect { subject }.not_to change(Task, :count)
      end
    end
  end
end
