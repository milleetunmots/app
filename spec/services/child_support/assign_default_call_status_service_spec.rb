require 'rails_helper'

RSpec.describe ChildSupport::AssignDefaultCallStatusService do

  let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }

  let!(:active_child) { FactoryBot.create(:child, group: group, group_status: 'active') }
  let!(:child_support_to_update) { active_child.child_support }

  let!(:inactive_child) { FactoryBot.create(:child, group: nil, group_status: 'waiting') }

  let!(:active_child_2) { FactoryBot.create(:child, group_status: 'active', group: group) }
  let!(:child_support_to_ignore_processed) { active_child_2.child_support }
  before do
    child_support_to_ignore_processed.update!(call1_status: 'OK')
  end

  let!(:other_group) { FactoryBot.create(:group) }
  let!(:other_group_child) { FactoryBot.create(:child, group_status: 'active', group: other_group) }
  let!(:child_support_other_group) { other_group_child.child_support }

  let(:service) { described_class.new(group.id, call_number) }
  let(:expected_details_prefix) { "Appel automatiquement passé en statut" }

  describe '#call' do
    context 'when handling call 1 (standard logic)' do
      let(:call_number) { 1 }

      context 'when call notes are present' do
        it "updates the status to 'OK'" do
          child_support_to_update.update!(call1_notes: 'Parent answered, everything is fine.')

          service.call
          child_support_to_update.reload

          expect(child_support_to_update.call1_status).to eq('OK')
          expect(child_support_to_update.call1_status_details).to include("#{expected_details_prefix} OK le")
        end
      end

      context 'when call duration is present' do
        it "updates the status to 'OK'" do
          child_support_to_update.update!(call1_duration: 120)

          service.call
          child_support_to_update.reload

          expect(child_support_to_update.call1_status).to eq('OK')
        end
      end

      context 'when both notes and duration are blank' do
        it "updates the status to 'KO'" do
          child_support_to_update.update!(call1_notes: '', call1_duration: nil)

          service.call
          child_support_to_update.reload

          expect(child_support_to_update.call1_status).to eq('KO')
          expect(child_support_to_update.call1_status_details).to include("#{expected_details_prefix} KO le")
        end
      end
    end

    context 'when handling call 0 (special notes logic)' do
      let(:call_number) { 0 }
      let(:call0_template) { "This is the default text for call 0." }

      before do
        allow(I18n).to receive(:t).with('child_support.default.call0_notes').and_return(call0_template)
      end

      context 'when notes are identical to the template' do
        it "updates the status to 'KO'" do
          child_support_to_update.update!(call0_notes: call0_template, call0_duration: nil)

          service.call
          child_support_to_update.reload

          expect(child_support_to_update.call0_status).to eq('KO')
        end
      end

      context 'when notes contain more than just the template' do
        it "updates the status to 'OK'" do
          child_support_to_update.update!(call0_notes: "#{call0_template}\nUser added this text.", call0_duration: nil)

          service.call
          child_support_to_update.reload

          expect(child_support_to_update.call0_status).to eq('OK')
        end
      end

      context 'when notes are completely blank' do
        it "updates the status to 'KO'" do
          child_support_to_update.update!(call0_notes: nil, call0_duration: nil)

          service.call
          child_support_to_update.reload

          expect(child_support_to_update.call0_status).to eq('KO')
        end
      end
    end

    context 'when handling call 2' do
      let(:call_number) { 2 }
      let!(:support_module) { FactoryBot.create(:support_module) }

      before do
        child_support_to_update.update!(call2_notes: nil, call2_duration: nil)
      end

      context "when a 'not programmed' support module exists" do
        it "updates the status to 'OK'" do
          FactoryBot.create(:children_support_module, is_programmed: false, child: active_child, support_module: support_module, parent: active_child.parent1)

          service.call
          child_support_to_update.reload

          expect(child_support_to_update.call2_status).to eq('OK')
        end
      end

      context "when only 'programmed' support modules exist" do
        it "updates the status to 'KO'" do
          FactoryBot.create(:children_support_module, is_programmed: true, child: active_child, support_module: support_module, parent: active_child.parent1)

          service.call
          child_support_to_update.reload

          expect(child_support_to_update.call2_status).to eq('KO')
        end
      end

      context 'when no support modules exist' do
        it "updates the status to 'KO'" do
          service.call
          child_support_to_update.reload

          expect(child_support_to_update.call2_status).to eq('KO')
        end
      end
    end

    context 'when handling data integrity' do
      let(:call_number) { 1 }

      it 'does not update child_supports that already have a status' do
        expect { service.call }.not_to(change { child_support_to_ignore_processed.reload.call1_status_details })
      end

      it 'does not update child_supports for inactive children' do
        inactive_child.update!(group: nil, group_status: 'waiting')

        expect { service.call }.not_to(change { inactive_child.child_support.reload.call1_status })
      end

      it 'does not update child_supports from other groups' do
        expect { service.call }.not_to(change { child_support_other_group.reload.call1_status })
      end

      it 'appends to existing status details' do
        child_support_to_update.update!(
          call1_notes: 'Note to pass validation',
          call1_status_details: 'Previous manual note.'
        )

        service.call
        child_support_to_update.reload

        expect(child_support_to_update.call1_status_details).to start_with("#{expected_details_prefix} OK le")
        expect(child_support_to_update.call1_status_details).to end_with('Previous manual note.')
      end
    end
  end
end
