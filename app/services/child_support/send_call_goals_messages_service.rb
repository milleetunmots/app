class ChildSupport::SendCallGoalsMessagesService

  REMINDER_BUNDLES = {
    0 => ['Rappel de petite mission — 2 semaines', 'rappel_mission_deux_semaines'],
    3 => ['Rappel de petite mission — appel 3', 'rappel_mission_appel3']
  }.freeze
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

      program_reminder
    end
  end

  def program_reminder
    return report_missing_reminder_bundle unless reminder_bundle

    service = ProgramAutomaticMessageService.new(
      @date.strftime('%d-%m-%Y'), '12:30', recipient,
      reminder_bundle.body1, reminder_bundle.rcs_media_id_to_send(1), reminder_bundle.redirection_target_id(1),
      automatic_message_key: REMINDER_BUNDLES[@call_index].last,
      recipient_variables: { @child_support.parent1.id => reminder_variables }
    ).call
    @errors << service.errors if service.errors
  end

  def reminder_bundle
    return @reminder_bundle if defined?(@reminder_bundle)

    name, key = REMINDER_BUNDLES[@call_index]
    @reminder_bundle = Media::TextMessagesBundle.find_automatic(name: name, key: key)
  end

  def report_missing_reminder_bundle
    return if @missing_reminder_bundle_reported

    @missing_reminder_bundle_reported = true
    name, key = REMINDER_BUNDLES[@call_index]
    @errors << Media::TextMessagesBundle.missing_message(name: name, key: key)
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

  def reminder_variables
    { 'PETITE_MISSION' => @goals_match[1]&.strip, 'LIEN_SUIVI_PETITE_MISSION' => @typeform_link_match[0] }
  end

  def send_text_messages_bundle
    report_missing_call3_bundles
    @group.child_supports.where.not(call3_goals_sms: [nil, '']).find_each do |child_support|
      @child_support = child_support
      @date = @group.started_at + 25.weeks
      call3_bundles.each_value do |bundle|
        @text_message_bundle = bundle
        program_text_message_bundles if bundle
        @date += 1.week
      end
    end
  end

  # Un trio par semaine, dans l'ordre de la liste : un trio introuvable laisse sa semaine vide.
  def call3_bundles
    @call3_bundles ||= ENV.fetch('CALL3_TEXT_MESSAGES_BUNDLES', '').dup.force_encoding(Encoding::UTF_8).split(',').map(&:strip).compact_blank
                          .index_with { |name| Media::TextMessagesBundle.kept.find_by(name: name) }
  end

  def report_missing_call3_bundles
    call3_bundles.each { |name, bundle| @errors << "Trio introuvable : « #{name} », message d'après l'appel 3 non envoyé" unless bundle }
  end

  def program_text_message_bundles
    program_text_message_bundle_body1
    program_text_message_bundle_body2
    program_text_message_bundle_body3
  end

  def program_text_message_bundle_body1
    return unless @text_message_bundle.body1

    service = ProgramMessageService.new(@date.next_occurring(:tuesday).strftime('%d-%m-%Y'), '12:30', recipient, @text_message_bundle.body1, @text_message_bundle.rcs_media_id_to_send(1), @text_message_bundle.link1_id).call
    @errors << service.errors if service.errors
  end

  def program_text_message_bundle_body2
    return unless @text_message_bundle.body2

    service = ProgramMessageService.new(@date.next_occurring(:thursday).strftime('%d-%m-%Y'), '12:30', recipient, @text_message_bundle.body2, @text_message_bundle.rcs_media_id_to_send(2), @text_message_bundle.link2_id).call
    @errors << service.errors if service.errors
  end

  def program_text_message_bundle_body3
    return unless @text_message_bundle.body3

    service = ProgramMessageService.new(@date.next_occurring(:saturday).strftime('%d-%m-%Y'), '12:30', recipient, @text_message_bundle.body3, @text_message_bundle.rcs_media_id_to_send(3), @text_message_bundle.link3_id).call
    @errors << service.errors if service.errors
  end
end
