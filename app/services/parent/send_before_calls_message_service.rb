class Parent::SendBeforeCallsMessageService

  PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGE = [
    <<~MSG0,
      Bonjour,
      C'est le début de votre accompagnement avec l'association 1001mots, qui va vous envoyer des SMS et des livres pour {PRENOM_ENFANT}.
      {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour vous expliquer comment ça se passe, faire connaissance et discuter avec vous :)
      Prenez rendez-vous avec elle ici : {CALL0_CALENDLY_LINK}
      A très bientôt !
      L'équipe 1001mots
    MSG0
    <<~MSG1,
      Bonjour,
      Vous avez bien reçu le 1er livre de l'association 1001mots pour {PRENOM_ENFANT} ? {PRENOM_ACCOMPAGNANTE} va vous appeler pour en discuter avec vous et vous donner des astuces pour l'utiliser avec {PRENOM_ENFANT} ;)
      Prenez rendez-vous avec elle ici : {CALL1_CALENDLY_LINK}
      A très bientôt !
      L'équipe 1001mots
    MSG1
    <<~MSG2,
      Bonjour,
      On espère que vous allez bien et {PRENOM_ENFANT} aussi :)
      {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour discuter avec vous du sujet que vous voulez concernant {PRENOM_ENFANT} et son langage.
      Prenez rendez-vous avec elle ici : {CALL2_CALENDLY_LINK}
      A très bientôt !
      L'équipe 1001mots
    MSG2
    <<~MSG3
      Bonjour,
      A 1001mots on espère que vous allez bien et {PRENOM_ENFANT} aussi :) {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour discuter avec vous de ce qui intéresse {PRENOM_ENFANT} en ce moment.
      Prenez rendez-vous avec {PRENOM_ACCOMPAGNANTE} ici : {CALL3_CALENDLY_LINK}
      A très bientôt !
      L'équipe 1001mots
    MSG3
  ].freeze

  AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGE = [
    <<~MSG1,
      Bonjour,
      Vous avez bien reçu le 1er livre de l'association 1001mots pour {PRENOM_ENFANT} ? {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour en discuter avec vous et vous donner des astuces pour l'utiliser avec {PRENOM_ENFANT} ;)
      Prenez rendez-vous avec {PRENOM_ACCOMPAGNANTE} ici : {CALL1_CALENDLY_LINK}
      Si elle n'arrive pas à vous parler au téléphone cette fois-ci, le programme va s'arrêter automatiquement :(
      A très bientôt !
      L'équipe 1001mots
    MSG1
    <<~MSG2,
      Bonjour,
      On espère que vous allez bien et {PRENOM_ENFANT} aussi :) {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour discuter avec vous et vous donner des astuces pour aider {PRENOM_ENFANT} avec son langage.
      Prenez rendez-vous avec {PRENOM_ACCOMPAGNANTE} ici : {CALL2_CALENDLY_LINK}
      Si elle n'arrive pas à vous parler au téléphone cette fois-ci, le programme va s'arrêter automatiquement :(
      A très bientôt !
      L'équipe 1001mots
    MSG2
    <<~MSG3
      Bonjour,
      On espère que vous allez bien et {PRENOM_ENFANT} aussi :) {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour discuter avec vous de ce qui intéresse {PRENOM_ENFANT} en ce moment.
      Prenez rendez-vous avec {PRENOM_ACCOMPAGNANTE} ici : {CALL3_CALENDLY_LINK}
      Si elle n'arrive pas à vous parler au téléphone cette fois-ci, le programme va s'arrêter automatiquement :(
      A très bientôt !
      L'équipe 1001mots
    MSG3
  ].freeze

  attr_reader :errors

  def initialize
    @errors = []
    @date = ENV['DISENGAGEMENT_WARNING_BEFORE_CALLS_DATE'].present? ? Date.parse(ENV['DISENGAGEMENT_WARNING_BEFORE_CALLS_DATE']) : Time.zone.today
    @groups = []
    4.times do |call_index|
      @groups << Group.with_calls.where("call#{call_index}_start_date = ?", @date.next_occurring(:monday))
    end
  end

  def call
    @groups.each_with_index do |group_list, call_index|
      group_list.each do |group|
        child_supports_with_correct_supporters = group.child_supports.with_valid_supporter_for_calendly
        child_supports_with_previous_calls_ok_or_unfinished =
          child_supports_with_correct_supporters.previous_calls_ok_or_unfinished_before(call_index)
        create_one_off_event_types(child_supports_with_previous_calls_ok_or_unfinished, call_index)
        send_before_calls_message(group, child_supports_with_previous_calls_ok_or_unfinished, PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGE[call_index])
        next if call_index.zero?

        child_support_with_at_least_one_call_not_ok_and_not_unfinished =
          child_supports_with_correct_supporters.at_least_one_call_not_ok_and_not_unfinished(call_index)
        create_one_off_event_types(child_support_with_at_least_one_call_not_ok_and_not_unfinished, call_index)
        send_before_calls_message(group, child_support_with_at_least_one_call_not_ok_and_not_unfinished, AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGE[call_index - 1])
      end
    end
    self
  end

  private

  def create_one_off_event_types(child_supports, call_index)
    return if child_supports.empty?

    child_supports.each do |child_support|
      create_one_off_event_type_service = Calendly::CreateOneOffEventTypeService.new(child_support: child_support, call_session: call_index).call
      @errors << "Parent::SendBeforeCallsMessageService (child_support: #{child_support.id}) : #{create_one_off_event_type_service.errors.uniq}" if create_one_off_event_type_service.errors.any?
    end
  end

  def parent_ids(child_supports)
    return if child_supports.empty?

    child_supports.map { |child_support| %W[parent.#{child_support.parent1.id} parent.#{child_support.parent2&.id}] }.flatten.compact
  end

  def send_before_calls_message(group, child_supports, message)
    return if child_supports.empty?

    message_service = ProgramMessageService.new(
      @date.strftime('%d-%m-%Y'),
      '19:00',
      parent_ids(child_supports),
      message
    ).call
    @errors << "Parent::SendBeforeCallsMessageService (group: #{group.name}) : #{message_service.errors.uniq}" if message_service.errors.any?
  end
end
