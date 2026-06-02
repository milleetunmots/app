require 'rails_helper'

RSpec.describe ChildSupport::AssignCalendlyInvitationChannelService do

  let(:rcs_tag) { described_class::RCS_TAG }
  let(:sms_tag) { described_class::SMS_TAG }

  let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }
  let!(:supporter) { FactoryBot.create(:admin_user) }

  def build_child_support(supporter_user: supporter, in_group: group, group_status: 'active', tags: [])
    child = FactoryBot.create(:child, group: in_group, group_status: group_status)
    cs = child.child_support
    cs.update!(supporter: supporter_user)
    tags.each { |t| cs.tag_list.add(t) }
    cs.save! if tags.any?
    cs
  end

  def tagged_with(child_supports, tag)
    child_supports.count { |cs| cs.reload.tag_list.include?(tag) }
  end

  before do
    allow(Rollbar).to receive(:info)
    allow(Rollbar).to receive(:error)
  end

  describe '#call' do
    context 'when assigning channels to child_supports of a single supporter' do
      let!(:cs_list) { Array.new(4) { build_child_support } }
      let(:scope) { ChildSupport.where(id: cs_list) }

      it 'splits child_supports in half between RCS and SMS' do
        described_class.new(scope).call

        expect(tagged_with(cs_list, rcs_tag)).to eq(2)
        expect(tagged_with(cs_list, sms_tag)).to eq(2)
      end

      it 'never assigns both tags to the same child_support' do
        described_class.new(scope).call

        cs_list.each do |cs|
          tags = cs.reload.tag_list
          expect(tags.count { |t| [rcs_tag, sms_tag].include?(t) }).to eq(1)
        end
      end

      it 'logs success to Rollbar with the assigned ids partitioned' do
        described_class.new(scope).call

        expect(Rollbar).to have_received(:info) do |_msg, rcs_child_support_ids:, sms_child_support_ids:|
          expect(rcs_child_support_ids.size).to eq(2)
          expect(sms_child_support_ids.size).to eq(2)
          expect(rcs_child_support_ids & sms_child_support_ids).to be_empty
          expect(rcs_child_support_ids + sms_child_support_ids).to match_array(cs_list.map(&:id))
        end
      end

      it 'returns the service instance with empty errors' do
        result = described_class.new(scope).call

        expect(result).to be_a(described_class)
        expect(result.errors).to be_empty
      end
    end

    context 'when the count is odd' do
      let!(:cs_list) { Array.new(3) { build_child_support } }
      let(:scope) { ChildSupport.where(id: cs_list) }

      it 'gives the extra child_support to the RCS group (ceil on the first slice)' do
        described_class.new(scope).call

        expect(tagged_with(cs_list, rcs_tag)).to eq(2)
        expect(tagged_with(cs_list, sms_tag)).to eq(1)
      end
    end

    context 'when child_supports are already tagged with a channel' do
      let!(:already_rcs) { build_child_support(tags: [rcs_tag]) }
      let!(:already_sms) { build_child_support(tags: [sms_tag]) }
      let!(:fresh) { build_child_support }

      let(:scope) { ChildSupport.where(id: [already_rcs, already_sms, fresh]) }

      it 'filters out child_supports already tagged with a channel at init' do
        described_class.new(scope).call

        expect(already_rcs.reload.tag_list).to include(rcs_tag)
        expect(already_rcs.tag_list).not_to include(sms_tag)

        expect(already_sms.reload.tag_list).to include(sms_tag)
        expect(already_sms.tag_list).not_to include(rcs_tag)
      end

      it 'still assigns a channel to the fresh child_support' do
        described_class.new(scope).call

        tags = fresh.reload.tag_list
        expect(tags & [rcs_tag, sms_tag]).not_to be_empty
      end
    end

    context 'when child_supports are not in an active group' do
      let!(:waiting_child_support) { build_child_support(in_group: nil, group_status: 'waiting') }
      let(:scope) { ChildSupport.where(id: [waiting_child_support]) }

      it 'filters them out at init and tags nothing' do
        described_class.new(scope).call

        expect(waiting_child_support.reload.tag_list & [rcs_tag, sms_tag]).to be_empty
      end
    end

    context 'when child_supports span multiple supporters' do
      let!(:other_supporter) { FactoryBot.create(:admin_user) }

      let!(:s1_list) { Array.new(2) { build_child_support(supporter_user: supporter) } }
      let!(:s2_list) { Array.new(2) { build_child_support(supporter_user: other_supporter) } }

      let(:scope) { ChildSupport.where(id: s1_list + s2_list) }

      it 'splits independently within each supporter group' do
        described_class.new(scope).call

        expect(tagged_with(s1_list, rcs_tag)).to eq(1)
        expect(tagged_with(s1_list, sms_tag)).to eq(1)

        expect(tagged_with(s2_list, rcs_tag)).to eq(1)
        expect(tagged_with(s2_list, sms_tag)).to eq(1)
      end
    end

    context 'when a save fails' do
      let!(:cs1) { build_child_support }
      let(:scope) { ChildSupport.where(id: [cs1]) }

      before do
        allow_any_instance_of(ChildSupport).to receive(:save).and_return(false)
        allow_any_instance_of(ChildSupport).to receive_message_chain(:errors, :full_messages)
          .and_return(['something went wrong'])
      end

      it 'collects the error and logs to Rollbar.error' do
        result = described_class.new(scope).call

        expect(result.errors).to include(
          hash_including(
            service: 'ChildSupport::AssignCalendlyInvitationChannelService',
            child_support_id: cs1.id,
            error: ['something went wrong']
          )
        )
        expect(Rollbar).to have_received(:error).with(
          'ChildSupport::AssignCalendlyInvitationChannelService failed',
          errors: array_including(hash_including(child_support_id: cs1.id))
        )
        expect(Rollbar).not_to have_received(:info)
      end
    end

    context 'when the scope is empty' do
      let(:scope) { ChildSupport.none }

      it 'does nothing and logs an empty success' do
        result = described_class.new(scope).call

        expect(result.errors).to be_empty
        expect(Rollbar).to have_received(:info).with(
          'ChildSupport::AssignCalendlyInvitationChannelService done',
          rcs_child_support_ids: [],
          sms_child_support_ids: []
        )
      end
    end
  end
end