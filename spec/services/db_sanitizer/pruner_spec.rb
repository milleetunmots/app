# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DbSanitizer::Pruner do
  subject(:pruner) { described_class.new(months_to_keep) }
  let(:months_to_keep) { 12 }

  describe '#call' do
    context 'when a child belongs to a recent group' do
      let(:recent_group) { FactoryBot.create(:group, created_at: 6.months.ago) }
      let!(:child) { FactoryBot.create(:child, group: recent_group, group_status: 'active') }

      it 'keeps the child' do
        pruner.call
        expect(Child.find_by(id: child.id)).to be_present
      end

      it 'keeps the parent' do
        pruner.call
        expect(Parent.find_by(id: child.parent1_id)).to be_present
      end
    end

    context 'when a child belongs to an old group' do
      let!(:recent_anchor_group) { FactoryBot.create(:group, created_at: 6.months.ago) }
      let(:old_group) { FactoryBot.create(:group, created_at: 2.years.ago) }
      let!(:child) { FactoryBot.create(:child, group: old_group, group_status: 'active') }

      it 'deletes the child' do
        pruner.call
        expect(Child.find_by(id: child.id)).to be_nil
      end

      it 'deletes the parent' do
        pruner.call
        expect(Parent.find_by(id: child.parent1_id)).to be_nil
      end
    end

    context 'when a parent has one child in a recent group and a sibling in an old group' do
      let(:recent_group) { FactoryBot.create(:group, created_at: 6.months.ago) }
      let(:old_group)    { FactoryBot.create(:group, created_at: 2.years.ago) }
      let!(:recent_child) { FactoryBot.create(:child, group: recent_group, group_status: 'active') }
      let!(:sibling) do
        FactoryBot.create(:child, parent1: recent_child.parent1, group: old_group, group_status: 'active')
      end

      it 'keeps the sibling (fratrie preserved)' do
        pruner.call
        expect(Child.find_by(id: sibling.id)).to be_present
      end
    end

    context 'when there are no groups in the last N months' do
      let!(:old_child) { FactoryBot.create(:child, group: FactoryBot.create(:group, created_at: 2.years.ago), group_status: 'active') }

      it 'deletes nothing (safety guard)' do
        expect { pruner.call }.not_to change(Child, :count)
      end
    end

    context 'when a child support has call archives' do
      let(:old_group) { FactoryBot.create(:group, created_at: 2.years.ago) }
      let(:recent_group) { FactoryBot.create(:group, created_at: 6.months.ago) }
      let!(:recent_child) { FactoryBot.create(:child, group: recent_group, group_status: 'active') }
      let!(:old_child) { FactoryBot.create(:child, group: old_group, group_status: 'active') }
      let!(:child_support) { old_child.child_support || FactoryBot.create(:child_support, current_child: old_child) }
      let!(:archive) { FactoryBot.create(:child_support_call_archive, child_support: child_support) }

      it 'deletes the call archive before deleting the child support' do
        pruner.call
        expect(ChildSupportCallArchive.find_by(id: archive.id)).to be_nil
      end
    end
  end
end
