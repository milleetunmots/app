require 'rails_helper'

RSpec.describe Parent::SendBeforeFirstCallMessageService do
  let(:date) { Date.new(2026, 6, 19) }
  let(:next_monday) { date.next_occurring(:monday) }
  let(:rcs_tag) { ChildSupport::AssignCalendlyInvitationChannelService::RCS_TAG }
  let(:sms_tag) { ChildSupport::AssignCalendlyInvitationChannelService::SMS_TAG }

  let!(:group) do
    FactoryBot.create(:group, expected_children_number: 0, type_of_support: 'with_calls', started_at: next_monday)
  end

  let!(:supporter) do
    FactoryBot.create(:admin_user, email: 'awa@1001mots.test', can_send_automatic_sms: true, calendly_user_uri: 'https://calendly.com/awa')
  end

  def build_cs(tag:)
    child = FactoryBot.create(:child, group: group, group_status: 'active')
    cs = child.child_support
    cs.update!(supporter: supporter)
    cs.tag_list.add(tag)
    cs.save!
    cs
  end

  let!(:sms_child_support) { build_cs(tag: sms_tag) }
  let!(:rcs_child_support) { build_cs(tag: rcs_tag) }

  let(:message_service_stub) do
    stub = instance_double(ProgramMessageService, errors: [])
    allow(stub).to receive(:call).and_return(stub)
    stub
  end
  let(:calendly_stub) { instance_double(Calendly::CreateOneOffEventTypeService, call: nil, errors: []) }

  subject(:service) { described_class.new(group_id: group.id, date: date) }

  before do
    stub_const('ENV', ENV.to_h.except('BETA_TEST_CALLERS_EMAIL').merge('RCS_CALL0_MEDIA_ID' => 'media-call0'))
    allow(ProgramMessageService).to receive(:new).and_return(message_service_stub)
    allow(Calendly::CreateOneOffEventTypeService).to receive(:new).and_return(calendly_stub)
    allow(calendly_stub).to receive(:call).and_return(calendly_stub)
  end

  describe '#handle_group_message' do
    it "envoie le SMS d'amont de session avec le lien Calendly de la session 0, en SMS puis en RCS" do
      service.handle_group_message(group, [sms_child_support.id, rcs_child_support.id])

      expect(ProgramMessageService).to have_received(:new).with(
        anything, anything, %W[parent.#{sms_child_support.parent1.id}], described_class::WARNING_MESSAGES, nil
      )
      expect(ProgramMessageService).to have_received(:new).with(
        anything, anything, %W[parent.#{rcs_child_support.parent1.id}], described_class::WARNING_MESSAGES, 'media-call0'
      )
    end

    it "n'envoie aucun message sans lien" do
      service.handle_group_message(group, [sms_child_support.id, rcs_child_support.id])

      expect(ProgramMessageService).to have_received(:new).exactly(2).times
    end

    it 'crée un lien Calendly à usage unique pour la session 0' do
      service.handle_group_message(group, [sms_child_support.id])

      expect(Calendly::CreateOneOffEventTypeService).to have_received(:new).with(
        child_support: have_attributes(id: sms_child_support.id), call_session: 0
      )
    end
  end
end
