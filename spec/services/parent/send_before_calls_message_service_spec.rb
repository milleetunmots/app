require 'rails_helper'

RSpec.describe Parent::SendBeforeCallsMessageService do

  let(:rcs_tag) { ChildSupport::AssignCalendlyInvitationChannelService::RCS_TAG }
  let(:sms_tag) { ChildSupport::AssignCalendlyInvitationChannelService::SMS_TAG }

  describe '#rcs_invitation_media_id (private)' do
    before do
      ENV['RCS_CALL0_MEDIA_ID'] = 'media-call0'
      ENV['RCS_CALL1_WITH_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID'] = 'media-call1-with'
      ENV['RCS_CALL1_WITHOUT_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID'] = 'media-call1-without'
      ENV['RCS_CALL2_WITH_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID'] = 'media-call2-with'
      ENV['RCS_CALL2_WITHOUT_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID'] = 'media-call2-without'
      ENV['RCS_CALL3_WITH_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID'] = 'media-call3-with'
      ENV['RCS_CALL3_WITHOUT_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID'] = 'media-call3-without'
    end

    after do
      %w[
        RCS_CALL0_MEDIA_ID
        RCS_CALL1_WITH_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID
        RCS_CALL1_WITHOUT_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID
        RCS_CALL2_WITH_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID
        RCS_CALL2_WITHOUT_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID
        RCS_CALL3_WITH_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID
        RCS_CALL3_WITHOUT_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID
      ].each { |k| ENV.delete(k) }
    end

    subject(:service) { described_class.new }

    [
      [0, true,  'media-call0'],
      [0, false, 'media-call0'],
      [1, true,  'media-call1-with'],
      [1, false, 'media-call1-without'],
      [2, true,  'media-call2-with'],
      [2, false, 'media-call2-without'],
      [3, true,  'media-call3-with'],
      [3, false, 'media-call3-without']
    ].each do |call_index, with_previous, expected_media|
      it "returns #{expected_media.inspect} for call_index=#{call_index} with_previous_call_ok_or_unfinished=#{with_previous}" do
        expect(
          service.send(:rcs_invitation_media_id, call_index, with_previous_call_ok_or_unfinished: with_previous)
        ).to eq(expected_media)
      end
    end

    it 'returns nil for an unknown call_index' do
      expect(service.send(:rcs_invitation_media_id, 99)).to be_nil
    end

    it 'returns nil when the ENV var is blank (presence-aware)' do
      ENV['RCS_CALL1_WITH_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID'] = ''
      expect(
        service.send(:rcs_invitation_media_id, 1, with_previous_call_ok_or_unfinished: true)
      ).to be_nil
    end
  end

  describe '#send_ab_tested_call_message (private)' do
    let!(:group) { FactoryBot.create(:group, expected_children_number: 0) }
    let!(:supporter) { FactoryBot.create(:admin_user) }

    let!(:sms_child_support) do
      child = FactoryBot.create(:child, group: group, group_status: 'active')
      cs = child.child_support
      cs.update!(supporter: supporter)
      cs.tag_list.add(sms_tag)
      cs.save!
      cs
    end

    let!(:rcs_child_support) do
      child = FactoryBot.create(:child, group: group, group_status: 'active')
      cs = child.child_support
      cs.update!(supporter: supporter)
      cs.tag_list.add(rcs_tag)
      cs.save!
      cs
    end

    let(:scope) { ChildSupport.where(id: [sms_child_support, rcs_child_support]) }
    let(:service) { described_class.new }
    let(:message) { 'hello {PRENOM_ENFANT}' }

    before do
      ENV['RCS_CALL1_WITH_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID'] = 'media-with'
      ENV['RCS_CALL1_WITHOUT_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID'] = 'media-without'

      stub = instance_double(ProgramMessageService, errors: [])
      allow(stub).to receive(:call).and_return(stub)
      allow(ProgramMessageService).to receive(:new).and_return(stub)
    end

    after do
      ENV.delete('RCS_CALL1_WITH_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID')
      ENV.delete('RCS_CALL1_WITHOUT_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID')
    end

    it 'passes the WITH media_id to the RCS batch when with_previous_call_ok_or_unfinished is true' do
      service.send(:send_ab_tested_call_message, group, scope, message, 1, with_previous_call_ok_or_unfinished: true)

      expect(ProgramMessageService).to have_received(:new).with(anything, anything, anything, message, 'media-with')
    end

    it 'passes the WITHOUT media_id to the RCS batch when with_previous_call_ok_or_unfinished is false' do
      service.send(:send_ab_tested_call_message, group, scope, message, 1, with_previous_call_ok_or_unfinished: false)

      expect(ProgramMessageService).to have_received(:new).with(anything, anything, anything, message, 'media-without')
    end

    it 'sends the SMS batch without any rcs_media_id (nil)' do
      service.send(:send_ab_tested_call_message, group, scope, message, 1, with_previous_call_ok_or_unfinished: true)

      expect(ProgramMessageService).to have_received(:new).with(anything, anything, anything, message, nil)
    end

    it 'splits recipients by tag: SMS-tagged go to the SMS batch, RCS-tagged go to the RCS batch' do
      service.send(:send_ab_tested_call_message, group, scope, message, 1, with_previous_call_ok_or_unfinished: true)

      sms_parent_ids = %W[parent.#{sms_child_support.parent1.id}]
      rcs_parent_ids = %W[parent.#{rcs_child_support.parent1.id}]

      expect(ProgramMessageService).to have_received(:new).with(anything, anything, sms_parent_ids, message, nil)
      expect(ProgramMessageService).to have_received(:new).with(anything, anything, rcs_parent_ids, message, 'media-with')
    end
  end

  describe '#call' do
    context 'when BETA_TEST_CALLERS_EMAIL is blank' do
      before { stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => '')) }

      it 'records an error and returns early without raising' do
        result = described_class.new.call

        expect(result.errors).to include(
          hash_including(
            service: 'Parent::SendBeforeCallsMessageService',
            error: 'BETA_TEST_CALLERS_EMAIL is not set'
          )
        )
      end
    end
  end

  describe '#handle_group_message (integration)' do
    let(:date) { Date.new(2026, 6, 19) }
    let(:next_monday) { date.next_occurring(:monday) }
    let(:beta_email) { 'beta@1001mots.test' }
    let(:other_email) { 'other@1001mots.test' }

    let(:ok)    { ChildSupport.human_attribute_name('call_status.1_ok') }
    let(:ko)    { ChildSupport.human_attribute_name('call_status.2_ko') }

    let!(:group) do
      FactoryBot.create(
        :group,
        expected_children_number: 0,
        type_of_support: 'with_calls',
        call1_start_date: next_monday
      )
    end

    let!(:beta_supporter) do
      FactoryBot.create(:admin_user, email: beta_email, can_send_automatic_sms: true, calendly_user_uri: 'https://calendly.com/beta')
    end
    let!(:non_beta_supporter) do
      FactoryBot.create(:admin_user, email: other_email, can_send_automatic_sms: true, calendly_user_uri: 'https://calendly.com/non-beta')
    end

    def build_cs(supporter:, call0_status:, tag: nil)
      child = FactoryBot.create(:child, group: group, group_status: 'active')
      cs = child.child_support
      cs.update!(supporter: supporter, call0_status: call0_status)
      if tag
        cs.tag_list.add(tag)
        cs.save!
      end
      cs
    end

    let!(:non_beta_ok)     { build_cs(supporter: non_beta_supporter, call0_status: ok) }
    let!(:non_beta_ko)     { build_cs(supporter: non_beta_supporter, call0_status: ko) }
    let!(:beta_ok_sms)     { build_cs(supporter: beta_supporter, call0_status: ok, tag: sms_tag) }
    let!(:beta_ok_rcs)     { build_cs(supporter: beta_supporter, call0_status: ok, tag: rcs_tag) }
    let!(:beta_ko_sms)     { build_cs(supporter: beta_supporter, call0_status: ko, tag: sms_tag) }
    let!(:beta_ko_rcs)     { build_cs(supporter: beta_supporter, call0_status: ko, tag: rcs_tag) }

    let(:message_service_stub) do
      stub = instance_double(ProgramMessageService, errors: [])
      allow(stub).to receive(:call).and_return(stub)
      stub
    end

    let(:calendly_stub) { instance_double(Calendly::CreateOneOffEventTypeService, call: nil, errors: []) }

    before do
      # stub_const et non une écriture dans ENV : un ENV.delete en `after`
      # supprimerait pour de bon des variables définies par application.yml,
      # cassant les specs suivantes selon l'ordre d'exécution.
      stub_const('ENV', ENV.to_h.merge(
                          'BETA_TEST_CALLERS_EMAIL' => beta_email,
                          'RCS_CALL1_WITH_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID' => 'media-with',
                          'RCS_CALL1_WITHOUT_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID' => 'media-without'
                        ))

      allow(ProgramMessageService).to receive(:new).and_return(message_service_stub)
      allow(Calendly::CreateOneOffEventTypeService).to receive(:new).and_return(calendly_stub)
      allow(calendly_stub).to receive(:call).and_return(calendly_stub)
      allow(Rollbar).to receive(:info)
      allow(Rollbar).to receive(:error)
    end


    it 'routes non-beta + previous calls OK to the NO_BETA OK message without media_id' do
      described_class.new(date: date).handle_group_message(group, 1)

      expect(ProgramMessageService).to have_received(:new).with(
        anything,
        anything,
        %W[parent.#{non_beta_ok.parent1.id}],
        described_class::NO_BETA_TEST_PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGES[0],
        nil
      )
    end

    it 'routes non-beta + at least one call not OK to the NO_BETA not-OK message without media_id' do
      described_class.new(date: date).handle_group_message(group, 1)

      expect(ProgramMessageService).to have_received(:new).with(
        anything,
        anything,
        %W[parent.#{non_beta_ko.parent1.id}],
        described_class::NO_BETA_TEST_AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGES[0],
        nil
      )
    end

    it 'routes beta + previous calls OK to two batches: SMS without media and RCS with the WITH media_id' do
      described_class.new(date: date).handle_group_message(group, 1)

      expect(ProgramMessageService).to have_received(:new).with(
        anything,
        anything,
        %W[parent.#{beta_ok_sms.parent1.id}],
        described_class::BETA_TEST_PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGES[0],
        nil
      )
      expect(ProgramMessageService).to have_received(:new).with(
        anything,
        anything,
        %W[parent.#{beta_ok_rcs.parent1.id}],
        described_class::BETA_TEST_PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGES[0],
        'media-with'
      )
    end

    it 'routes beta + at least one call not OK to two batches: SMS without media and RCS with the WITHOUT media_id' do
      described_class.new(date: date).handle_group_message(group, 1)

      expect(ProgramMessageService).to have_received(:new).with(
        anything,
        anything,
        %W[parent.#{beta_ko_sms.parent1.id}],
        described_class::BETA_TEST_AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGES[0],
        nil
      )
      expect(ProgramMessageService).to have_received(:new).with(
        anything,
        anything,
        %W[parent.#{beta_ko_rcs.parent1.id}],
        described_class::BETA_TEST_AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGES[0],
        'media-without'
      )
    end

    it 'creates Calendly one-off event types only for beta-test child supports' do
      described_class.new(date: date).handle_group_message(group, 1)

      beta_cs_ids = [beta_ok_sms, beta_ok_rcs, beta_ko_sms, beta_ko_rcs].map(&:id)
      non_beta_cs_ids = [non_beta_ok, non_beta_ko].map(&:id)

      beta_cs_ids.each do |id|
        expect(Calendly::CreateOneOffEventTypeService).to have_received(:new).with(
          child_support: have_attributes(id: id), call_session: 1
        )
      end
      non_beta_cs_ids.each do |id|
        expect(Calendly::CreateOneOffEventTypeService).not_to have_received(:new).with(
          child_support: have_attributes(id: id), call_session: anything
        )
      end
    end

    it 'issues exactly 6 ProgramMessageService calls (2 non-beta SMS batches + 2 beta SMS batches + 2 beta RCS batches)' do
      described_class.new(date: date).handle_group_message(group, 1)

      expect(ProgramMessageService).to have_received(:new).exactly(6).times
    end
  end
end