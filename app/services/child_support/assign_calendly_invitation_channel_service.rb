class ChildSupport::AssignCalendlyInvitationChannelService

  RCS_TAG = 'ab_testing_calendly_invite_rcs'.freeze
  SMS_TAG = 'ab_testing_calendly_invite_sms'.freeze
  CHANNELS = [RCS_TAG, SMS_TAG].freeze

  attr_reader :errors, :rcs_child_support_ids, :sms_child_support_ids

  def initialize(child_supports)
    @child_supports = child_supports.to_a
    @errors = []
    @rcs_child_support_ids = []
    @sms_child_support_ids = []
  end

  def call
    @child_supports.group_by(&:supporter_id).each_value do |_, child_supports|
      child_supports = child_supports.not_tagged_with_all(CHANNELS).shuffle
      rcs_child_support, sms_child_support = child_supports.each_slice((child_supports.count / 2.0).ceil).to_a

      rcs_child_support.each do |child_support|
        next if child_support.tag_list.include?(RCS_TAG) || child_support.tag_list.include?(SMS_TAG)

        child_support.tag_list.add(RCS_TAG)
        if child_support.save
          @rcs_child_support_ids << child_support.id
        else
          @errors << {
            service: 'ChildSupport::ABTestingCalendlyInviteRcsSmsService',
            child_support_id: child_support.id,
            error: child_support.errors.full_messages
          }
        end
      end

      sms_child_support.each do |child_support|
        next if child_support.tag_list.include?(RCS_TAG) || child_support.tag_list.include?(SMS_TAG)

        child_support.tag_list.add(SMS_TAG)
        if child_support.save
          @sms_child_support_ids << child_support.id
        else
          @errors << {
            service: 'ChildSupport::ABTestingCalendlyInviteRcsSmsService',
            child_support_id: child_support.id,
            error: child_support.errors.full_messages
          }
        end
      end
    end

    if @errors.empty?
      Rollbar.info(
        'ChildSupport::AssignCalendlyInvitationChannelService done',
        rcs_child_support_ids: @rcs_child_support_ids,
        sms_child_support_ids: @sms_child_support_ids
      )
    else
      Rollbar.error(
        'ChildSupport::AssignCalendlyInvitationChannelService failed',
        errors: @errors
      )
    end
    self
  end
end
