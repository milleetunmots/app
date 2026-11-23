class ChildSupport::SendCall0GoalsReminderMessagesService

  BUNDLE = ['Rappel de petite mission — appel 0', 'rappel_mission_appel0'].freeze
  CALL_GOALS_REGEX = /Voici votre petite mission :\r\n([\s\S]*?)\r\nQuand vous aurez essayé/.freeze
  TYPEFORM_URL_REGEX = /https?:\/\/[^\/]+\/c[03](\/\S*)?(\?\S+)?/.freeze

  attr_reader :errors

  def initialize(group_id)
    @group = Group.find(group_id)
    @date = @group.started_at + 6.weeks
    @errors = []
  end

  def call
    @group.child_supports.where(call1_previous_goals_follow_up: [nil, '']).where.not(call0_goals_sms: [nil, '']).where.not(call1_status: 'OK').find_each do |child_support|
      @child_support = child_support
      message_informations
      next unless @call_goal.present? && @typeform_link.present?

      program_reminder
    end
    self
  end

  private

  def message_informations
    @call_goal = @child_support.call0_goal_sent.presence || @child_support.call0_goals_sms.match(CALL_GOALS_REGEX)&.[](1)&.strip
    @typeform_link = @child_support.call0_goals_sms.match(TYPEFORM_URL_REGEX)&.[](0)
    @recipient = ["parent.#{@child_support.parent1.id}"]
  end

  def program_reminder
    return report_missing_bundle unless bundle

    service = ProgramAutomaticMessageService.new(
      @date.strftime('%d-%m-%Y'), '12:30', @recipient,
      bundle.body1, bundle.rcs_media_id_to_send(1), bundle.redirection_target_id(1),
      automatic_message_key: BUNDLE.last,
      recipient_variables: { @child_support.parent1.id => { 'PETITE_MISSION' => @call_goal, 'LIEN_SUIVI_PETITE_MISSION' => @typeform_link } }
    ).call
    @errors << service.errors if service.errors
  end

  def bundle
    return @bundle if defined?(@bundle)

    @bundle = Media::TextMessagesBundle.find_automatic(name: BUNDLE.first, key: BUNDLE.last)
  end

  def report_missing_bundle
    return if @missing_bundle_reported

    @missing_bundle_reported = true
    @errors << Media::TextMessagesBundle.missing_message(name: BUNDLE.first, key: BUNDLE.last)
  end
end
