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
    it "n'expose plus d'entrée #call : le flux ne passe que par handle_group_message" do
      expect(described_class.new).not_to respond_to(:call)
    end
  end

  describe '#handle_group_message (integration)' do
    let(:date) { Date.new(2026, 6, 19) }
    let(:next_monday) { date.next_occurring(:monday) }
    let(:supporter_email) { 'awa@1001mots.test' }

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

    let!(:supporter) do
      FactoryBot.create(:admin_user, email: supporter_email, can_send_automatic_sms: true, calendly_user_uri: 'https://calendly.com/awa')
    end

    def build_cs(call0_status:, tag:)
      child = FactoryBot.create(:child, group: group, group_status: 'active')
      cs = child.child_support
      cs.update!(supporter: supporter, call0_status: call0_status)
      cs.tag_list.add(tag)
      cs.save!
      cs
    end

    let!(:ok_sms) { build_cs(call0_status: ok, tag: sms_tag) }
    let!(:ok_rcs) { build_cs(call0_status: ok, tag: rcs_tag) }
    let!(:ko_sms) { build_cs(call0_status: ko, tag: sms_tag) }
    let!(:ko_rcs) { build_cs(call0_status: ko, tag: rcs_tag) }

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
      stub_const('ENV', ENV.to_h.except('BETA_TEST_CALLERS_EMAIL').merge(
                          'RCS_CALL1_WITH_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID' => 'media-with',
                          'RCS_CALL1_WITHOUT_PREVIOUS_CALL_OK_OR_UNFINISHED_MEDIA_ID' => 'media-without'
                        ))

      allow(ProgramMessageService).to receive(:new).and_return(message_service_stub)
      allow(Calendly::CreateOneOffEventTypeService).to receive(:new).and_return(calendly_stub)
      allow(calendly_stub).to receive(:call).and_return(calendly_stub)
      allow(Rollbar).to receive(:info)
      allow(Rollbar).to receive(:error)
    end

    it "envoie, sans dépendre d'une liste bêta, deux lots (SMS sans media, RCS avec le media WITH) quand les appels précédents sont OK" do
      described_class.new(date: date).handle_group_message(group, 1)

      expect(ProgramMessageService).to have_received(:new).with(
        anything,
        anything,
        %W[parent.#{ok_sms.parent1.id}],
        described_class::PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGES[0],
        nil
      )
      expect(ProgramMessageService).to have_received(:new).with(
        anything,
        anything,
        %W[parent.#{ok_rcs.parent1.id}],
        described_class::PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGES[0],
        'media-with'
      )
    end

    it 'envoie deux lots (SMS sans media, RCS avec le media WITHOUT) quand au moins un appel précédent est KO' do
      described_class.new(date: date).handle_group_message(group, 1)

      expect(ProgramMessageService).to have_received(:new).with(
        anything,
        anything,
        %W[parent.#{ko_sms.parent1.id}],
        described_class::AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGES[0],
        nil
      )
      expect(ProgramMessageService).to have_received(:new).with(
        anything,
        anything,
        %W[parent.#{ko_rcs.parent1.id}],
        described_class::AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGES[0],
        'media-without'
      )
    end

    it 'crée un lien Calendly à usage unique pour chaque fiche de suivi' do
      described_class.new(date: date).handle_group_message(group, 1)

      [ok_sms, ok_rcs, ko_sms, ko_rcs].map(&:id).each do |id|
        expect(Calendly::CreateOneOffEventTypeService).to have_received(:new).with(
          child_support: have_attributes(id: id), call_session: 1
        )
      end
    end

    it "n'envoie aucun message sans lien : 4 appels à ProgramMessageService (2 lots SMS et 2 lots RCS)" do
      described_class.new(date: date).handle_group_message(group, 1)

      expect(ProgramMessageService).to have_received(:new).exactly(4).times
    end

    it "ne dépend pas de BETA_TEST_CALLERS_EMAIL : une liste contenant d'autres e-mails donne le même résultat" do
      stub_const('ENV', ENV.to_h.merge('BETA_TEST_CALLERS_EMAIL' => 'other@1001mots.test'))

      described_class.new(date: date).handle_group_message(group, 1)

      expect(ProgramMessageService).to have_received(:new).exactly(4).times
    end
  end
end
