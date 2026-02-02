class ChildSupport::SendCallGoalsMessagesService

  CALL_GOALS_REMINDER_MESSAGE = "Bonjour\nVoici un rappel de votre petite mission 1001mots :\n{call_goals}\nEt pour me raconter comment ça c'est passé, c'est ici :\n{typeform_link}\nÀ bientôt :)".freeze
  CALL_GOALS_REGEX = /Voici votre petite mission :\r\n([\s\S]*?)\r\nQuand vous aurez essayé/.freeze
  TYPEFORM_URL_REGEX = /https?:\/\/[^\/]+\/c[03](\/\S*)?(\?\S+)?/.freeze

  attr_reader :errors

  def initialize(group_id, call_index)
    @group = Group.find(group_id)
    @call_index = call_index.to_i
    @date = @group.started_at + (@call_index == 3 ? 25.weeks : + 2.weeks)
    @errors = []
  end

  def call
    send_call_goals_reminder_message
    send_text_messages_bundle if @call_index == 3
    self
  end

  private

  def send_call_goals_reminder_message
    call_informations
    # call4 doesnt exist anymore
    qwery =
      if @call_previous_goals_follow_up == 'call4_previous_goals_follow_up'
        @group.child_supports.where.not(@call_goals_sms.to_sym => [nil, ''])
      else
        @group.child_supports.where.not(@call_goals_sms.to_sym => [nil, '']).where.not(@call_previous_goals_follow_up.to_sym => '1_succeed')
      end
    qwery.find_each do |child_support|
      @child_support = child_support
      message_informations
      next unless @goals_match.present? && @typeform_link_match.present?

      service = ProgramMessageService.new(@date.strftime('%d-%m-%Y'), '12:30', recipient, reminder_message).call
      @errors << service.errors if service.errors
    end
  end

  def call_informations
    if @call_index == 3
      @call_goals_sms = 'call3_goals_sms'
      # call4 doesnt exist anymore
      @call_previous_goals_follow_up = 'call4_previous_goals_follow_up'
    else
      @call_goals_sms = 'call0_goals_sms'
      @call_previous_goals_follow_up = 'call1_previous_goals_follow_up'
    end
  end

  def message_informations
    @goals_match = @child_support.send(@call_goals_sms).match(CALL_GOALS_REGEX)
    @typeform_link_match = @child_support.send(@call_goals_sms).match(TYPEFORM_URL_REGEX)
  end

  def recipient
    ["parent.#{@child_support.parent1.id}"]
  end

  def reminder_message
    call_goals = @goals_match[1]&.strip
    typeform_link = @typeform_link_match[0]
    message = CALL_GOALS_REMINDER_MESSAGE
    message = message.gsub('À bientôt', 'Bonne journée') if @call_index == 3
    message.gsub('{call_goals}', call_goals).gsub('{typeform_link}', typeform_link)
  end

  def send_text_messages_bundle
    @group.child_supports.where.not(call3_goals_sms: [nil, '']).find_each do |child_support|
      @child_support = child_support
      @date = @group.started_at + 25.weeks
      ENV['CALL3_TEXT_MESSAGES_BUNDLES'].split(',').each do |text_messages_bundle_name|
        @text_message_bundle = Media::TextMessagesBundle.kept.find_by(name: text_messages_bundle_name.strip)
        program_text_message_bundles
        @date += 1.week
      end
    end
  end

  def program_text_message_bundles
    program_text_message_bundle_body1
    program_text_message_bundle_body2
    program_text_message_bundle_body3
  end

  def program_text_message_bundle_body1
    return unless @text_message_bundle.body1

    spot_hit_id = @text_message_bundle.image1_id.present? ? Media::Image.find(@text_message_bundle.image1_id)&.spot_hit_id : nil
    service = ProgramMessageService.new(@date.next_occurring(:tuesday).strftime('%d-%m-%Y'), '12:30', recipient, @text_message_bundle.body1, spot_hit_id, @text_message_bundle.link1_id).call
    @errors << service.errors if service.errors
  end

  def program_text_message_bundle_body2
    return unless @text_message_bundle.body2

    spot_hit_id = @text_message_bundle.image2_id.present? ? Media::Image.find(@text_message_bundle.image2_id)&.spot_hit_id : nil
    service = ProgramMessageService.new(@date.next_occurring(:thursday).strftime('%d-%m-%Y'), '12:30', recipient, @text_message_bundle.body2, spot_hit_id, @text_message_bundle.link2_id).call
    @errors << service.errors if service.errors
  end

  def program_text_message_bundle_body3
    return unless @text_message_bundle.body3

    spot_hit_id = @text_message_bundle.image3_id.present? ? Media::Image.find(@text_message_bundle.image3_id)&.spot_hit_id : nil
    service = ProgramMessageService.new(@date.next_occurring(:saturday).strftime('%d-%m-%Y'), '12:30', recipient, @text_message_bundle.body3, spot_hit_id, @text_message_bundle.link3_id).call
    @errors << service.errors if service.errors
  end
end
