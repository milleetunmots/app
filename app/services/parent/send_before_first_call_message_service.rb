class Parent::SendBeforeFirstCallMessageService < Parent::SendBeforeCallsMessageService

  def initialize(group_id:, date: , send_at: nil)
    @errors = []
    @date = date
    @send_at = send_at
    @group = Group.find_by(id: group_id)
  end

  def call
    @errors << { service: 'Parent::SendBeforeFirstCallMessageService', error: 'BETA_TEST_CALLERS_EMAIL is not set' } if ENV['BETA_TEST_CALLERS_EMAIL'].blank?
    @errors << { service: 'Parent::SendBeforeFirstCallMessageService', error: 'group is not found' } if @group.nil?
    return self if @errors.any?

    non_beta_child_support_ids = @group.child_supports
                                       .with_valid_supporter_for_calendly
                                       .where.not(supporter: { email: ENV['BETA_TEST_CALLERS_EMAIL'].split })
                                       .distinct
                                       .pluck(:id)
    handle_group_message(@group, non_beta_child_support_ids) if non_beta_child_support_ids.any?
    self
  end

  def handle_group_message(group, child_support_ids = [])
    child_supports_with_correct_supporters =
      if child_support_ids.any?
        ChildSupport.where(id: child_support_ids).with_valid_supporter_for_calendly
      else
        group.child_supports.with_valid_supporter_for_calendly
      end

    no_beta_test_child_supports =
      child_supports_with_correct_supporters.where.not(supporter: { email: ENV['BETA_TEST_CALLERS_EMAIL'].split })
    send_before_calls_message(group, no_beta_test_child_supports, NO_BETA_TEST_WARNING_MESSAGES, 0)

    beta_test_child_supports =
      child_supports_with_correct_supporters.where(supporter: { email: ENV['BETA_TEST_CALLERS_EMAIL'].split })
    create_one_off_event_types(beta_test_child_supports, 0)
    assign_calendly_invitation_channel(beta_test_child_supports)
    send_ab_tested_call_message(group, beta_test_child_supports, BETA_TEST_WARNING_MESSAGES, 0)
  end

end
