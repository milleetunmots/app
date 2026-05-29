class ChildSupport::AssignInvitationChannelService

  RCS_TAG = 'rcs_invitation'.freeze
  SMS_TAG = 'sms_invitation'.freeze
  CHANNELS = [RCS_TAG, SMS_TAG].freeze

  attr_reader :errors, :rcs_child_support_ids, :sms_child_support_ids

  def initialize(child_supports)
    @child_supports = child_supports.to_a
    @supporter_ids = @child_supports.map(&:supporter_id).compact.uniq
    @errors = []
    @rcs_child_support_ids = []
    @sms_child_support_ids = []
  end

  def call
    counts = initial_counts_per_supporter

    @child_supports.each do |child_support|
      channel = existing_channel(child_support) || assign_channel(child_support, counts)
      (channel == RCS_TAG ? @rcs_child_support_ids : @sms_child_support_ids) << child_support.id
    end

    if @errors.empty?
      Rollbar.info(
        'ChildSupport::AssignInvitationChannelService: assignation des canaux réussie',
        rcs_child_support_ids: @rcs_child_support_ids,
        sms_child_support_ids: @sms_child_support_ids
      )
    end
    self
  end

  private

  def initial_counts_per_supporter
    rcs = ChildSupport.tagged_with(RCS_TAG).where(supporter_id: @supporter_ids).group(:supporter_id).count
    sms = ChildSupport.tagged_with(SMS_TAG).where(supporter_id: @supporter_ids).group(:supporter_id).count
    @supporter_ids.index_with { |id| { RCS_TAG => rcs[id].to_i, SMS_TAG => sms[id].to_i } }
  end

  def existing_channel(child_support)
    tags = child_support.tag_list
    return RCS_TAG if tags.include?(RCS_TAG)
    return SMS_TAG if tags.include?(SMS_TAG)

    nil
  end

  def assign_channel(child_support, counts)
    tally = counts[child_support.supporter_id] ||= { RCS_TAG => 0, SMS_TAG => 0 }

    channel =
      if tally[RCS_TAG] < tally[SMS_TAG]
        RCS_TAG
      elsif tally[SMS_TAG] < tally[RCS_TAG]
        SMS_TAG
      else
        CHANNELS.sample
      end


    child_support.tag_list.add(channel)
    if child_support.save
      tally[channel] += 1
      channel
    else
      @errors << {
        service: 'ChildSupport::AssignInvitationChannelService',
        child_support_id: child_support.id,
        error: child_support.errors.full_messages
      }
    end
  end
end
