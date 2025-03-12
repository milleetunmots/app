class ChildSupport::SendCall0GoalsReminderMessagesService

  CALL_GOALS_REMINDER_MESSAGE = "1001mots: Je n'ai pas réussi à vous joindre cette fois-ci, tant pis! Voici un rappel de votre petite mission de la dernière fois:\n{call_goals}\nVous pouvez me dire si vous avez essayé en cliquant sur ce lien:\n{typeform_link}\nÀ bientôt!".freeze
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
      @typeform_link_match = @child_support.call0_goals_sms.match(TYPEFORM_URL_REGEX)
      next unless @call_goal.present? && @typeform_link.present?

      service = ProgramMessageService.new(@date.strftime('%d-%m-%Y'), '12:30', @recipient, @reminder_message).call
      @errors << service.errors if service.errors
    end
    self
  end

  private

  def message_informations
    @call_goal = @child_support.call0_goal_sent.presence || @child_support.call0_goals_sms.match(CALL_GOALS_REGEX)[1]&.strip
    @typeform_link = @child_support.call0_goals_sms.match(TYPEFORM_URL_REGEX)[0]
    @reminder_message = CALL_GOALS_REMINDER_MESSAGE.gsub('{call_goals}', @call_goal).gsub('{typeform_link}', @typeform_link)
    @recipient = ["parent.#{@child_support.parent1.id}"]
  end
end
