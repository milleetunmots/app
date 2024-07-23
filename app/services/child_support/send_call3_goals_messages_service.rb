class ChildSupport::SendCall3GoalsMessagesService

  CALL3_GOALS_REMINDER_MESSAGE = "Rappel de votre petite mission:\n{call3_goals}\n{typeform_link}".freeze
  CALL3_GOALS_REGEX = /Voici votre petite mission :\r\n(.*?)\r\nQuand vous aurez essayé/
  TYPEFORM_URL_REGEX = /https:\/\/form\.typeform\.com\/to\/\S+/

  def initialize(group_id)
    @group = Group.find(group_id)
    @date = @group.started_at + 25.weeks
  end

  def call
    send_call3_goals_reminder_message
    send_text_messages_bundle
  end

  private

  def reminder_message
    call3_goals = @child_support.call3_goals_sms.match(CALL3_GOALS_REGEX)[1]&.strip
    typeform_link = @child_support.call3_goals_sms.match(TYPEFORM_URL_REGEX)[0]
    CALL3_GOALS_REMINDER_MESSAGE.gsub('{call3_goals}', call3_goals).gsub('{typeform_link}', typeform_link)
  end

  def recipient
    ["parent.#{@child_support.parent1.id}"]
  end

  def program_text_message_bundles
    ProgramMessageService.new(@date.next_occurring(:tuesday).strftime('%d-%m-%Y'), '12:30', recipient, @text_message_bundle.body1, @text_message_bundle.image1_id, @text_message_bundle.link1_id).call if @text_message_bundle.body1
    ProgramMessageService.new(@date.next_occurring(:thursday).strftime('%d-%m-%Y'), '12:30', recipient, @text_message_bundle.body2, @text_message_bundle.image2_id, @text_message_bundle.link2_id).call if @text_message_bundle.body2
    ProgramMessageService.new(@date.next_occurring(:saturday).strftime('%d-%m-%Y'), '12:30', recipient, @text_message_bundle.body3, @text_message_bundle.image3_id, @text_message_bundle.link3_id).call if @text_message_bundle.body3
  end

  def send_call3_goals_reminder_message
    @group.child_supports.where.not(call3_goals_sms: nil).where.not(call4_previous_goals_follow_up: '1_succeed').find_each do |child_support|
      @child_support = child_support
      ProgramMessageService.new(@date.strftime('%d-%m-%Y'), '12:30', recipient, reminder_message).call
    end
  end

  def send_text_messages_bundle
    @group.child_supports.where.not(call3_goals_sms: nil).find_each do |child_support|
      @child_support = child_support
      @date = @group.started_at + 25.weeks
      ENV['CALL3_TEXT_MESSAGES_BUNDLES'].split(',').each do |text_messages_bundle_name|
        @text_message_bundle = Media::TextMessagesBundle.kept.find_by(name: text_messages_bundle_name.split)
        program_text_message_bundles
        @date += 1.week
      end
    end
  end
end
