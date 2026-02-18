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

    handle_group_message(@group)
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
    send_before_calls_message(group, no_beta_test_child_supports, NO_BETA_TEST_WARNING_MESSAGES)

    beta_test_child_supports =
      child_supports_with_correct_supporters.where(supporter: { email: ENV['BETA_TEST_CALLERS_EMAIL'].split })
    create_one_off_event_types(beta_test_child_supports, 0)
    send_before_calls_message(group, beta_test_child_supports, BETA_TEST_WARNING_MESSAGES)
  end
end
