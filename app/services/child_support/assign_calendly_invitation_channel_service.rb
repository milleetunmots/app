class ChildSupport::AssignCalendlyInvitationChannelService

  RCS_TAG = 'ab_testing_calendly_invite_rcs'.freeze
  SMS_TAG = 'ab_testing_calendly_invite_sms'.freeze
  CHANNELS = [RCS_TAG, SMS_TAG].freeze

  attr_reader :errors

  def initialize(child_supports)
    @child_supports = child_supports.with_a_child_in_active_group.not_tagged_with_all(CHANNELS).distinct.to_a.group_by(&:supporter_id)
    @errors = []
    @rcs_child_support_ids = []
    @sms_child_support_ids = []
  end

  def call
    @child_supports.each_value do |child_supports|
      child_supports = child_supports.shuffle
      rcs_child_supports, sms_child_supports = child_supports.each_slice((child_supports.count / 2.0).ceil).to_a

      add_tag(rcs_child_supports, RCS_TAG, @rcs_child_support_ids)
      add_tag(sms_child_supports, SMS_TAG, @sms_child_support_ids)
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

  private

  def add_tag(child_supports, tag, ids)
    return if child_supports.nil?

    child_supports.each do |child_support|
      next if child_support.tag_list.include?(RCS_TAG) || child_support.tag_list.include?(SMS_TAG)

      child_support.tag_list += [tag]
      if child_support.save
        ids << child_support.id
      else
        @errors << {
          service: 'ChildSupport::AssignCalendlyInvitationChannelService',
          child_support_id: child_support.id,
          error: child_support.errors.full_messages
        }
      end
    end
  end
end
