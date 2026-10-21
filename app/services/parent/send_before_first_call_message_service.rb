class Parent::SendBeforeFirstCallMessageService < Parent::SendBeforeCallsMessageService

  def initialize(group_id:, date: , send_at: nil)
    @errors = []
    @date = date
    @send_at = send_at
    @group = Group.find_by(id: group_id)
  end

  def handle_group_message(group, child_support_ids = [])
    child_supports_with_correct_supporters =
      if child_support_ids.any?
        ChildSupport.where(id: child_support_ids).with_valid_supporter_for_calendly
      else
        group.child_supports.with_valid_supporter_for_calendly
      end

    create_one_off_event_types(child_supports_with_correct_supporters, 0)
    assign_calendly_invitation_channel(child_supports_with_correct_supporters)
    send_ab_tested_call_message(group, child_supports_with_correct_supporters, WARNING_MESSAGES, 0)
  end

end
