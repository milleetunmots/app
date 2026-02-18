class Parent::SendBeforeCallsMessageService

  NO_BETA_TEST_WARNING_MESSAGES =
    <<~MSG.freeze
      Bonjour,
      C'est le début de votre accompagnement avec l'association 1001mots, qui va vous envoyer des SMS et des livres pour {PRENOM_ENFANT}.
      {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour vous expliquer comment ça se passe, faire connaissance et discuter avec vous :)
      Pensez à enregistrer son numéro {NUMERO_AIRCALL_ACCOMPAGNANTE}
      A très bientôt !
      L'équipe 1001mots
    MSG

  BETA_TEST_WARNING_MESSAGES =
    <<~MSG.freeze
      Bonjour,
      C'est le début de votre accompagnement avec l'association 1001mots, qui va vous envoyer des SMS et des livres pour {PRENOM_ENFANT}.
      {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour vous expliquer comment ça se passe, faire connaissance et discuter avec vous :)
      Prenez rendez-vous avec elle ici : {CALL0_CALENDLY_LINK}
      A très bientôt !
      L'équipe 1001mots
    MSG

  NO_BETA_TEST_PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGES = [
    <<~MSG1,
      Bonjour,
      Vous avez bien reçu le 1er livre de l’association 1001mots pour {PRENOM_ENFANT} ? {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour en discuter avec vous et vous donner des astuces pour l'utiliser avec {PRENOM_ENFANT} ;)
      Pensez à enregistrer son numéro {NUMERO_AIRCALL_ACCOMPAGNANTE}
      A très bientôt !
      L'équipe 1001mots
    MSG1
    <<~MSG2,
      Bonjour,
      A 1001mots on espère que vous allez bien et {PRENOM_ENFANT} aussi :) {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour prendre des nouvelles, discuter avec vous et vous donner des astuces pour aider {PRENOM_ENFANT} avec son langage.
      A très bientôt !
      L'équipe 1001mots
    MSG2
    <<~MSG3
      Bonjour,
      A 1001mots on espère que vous allez bien et {PRENOM_ENFANT} aussi :) {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour discuter avec vous de ce qui intéresse {PRENOM_ENFANT} en ce moment.
      A très bientôt !
      L'équipe 1001mots
    MSG3
  ].freeze

  NO_BETA_TEST_AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGES = [
    <<~MSG1,
      Bonjour,
      Vous avez bien reçu le 1er livre de l'association 1001mots pour {PRENOM_ENFANT} ? {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour en discuter avec vous et vous donner des astuces pour l'utiliser avec {PRENOM_ENFANT} ;)
      Si elle n'arrive pas à vous parler au téléphone cette fois-ci, le programme va s'arrêter automatiquement :( Pensez à enregistrer son numéro {NUMERO_AIRCALL_ACCOMPAGNANTE}
      A très bientôt !
      L'équipe 1001mots
    MSG1
    <<~MSG2,
      Bonjour,
      A 1001mots on espère que vous allez bien et {PRENOM_ENFANT} aussi :) {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour prendre des nouvelles, discuter avec vous et vous donner des astuces pour aider {PRENOM_ENFANT} avec son langage.
      Si elle n’arrive pas à vous parler au téléphone cette fois-ci, le programme va s’arrêter automatiquement :(
      A très bientôt !
      L’équipe 1001mots
    MSG2
    <<~MSG3
      Bonjour,
      A 1001mots on espère que vous allez bien et {PRENOM_ENFANT} aussi :) {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour discuter avec vous de ce qui intéresse {PRENOM_ENFANT} en ce moment.
      Si elle n’arrive pas à vous parler au téléphone cette fois-ci, le programme va s’arrêter automatiquement :(
      A très bientôt !
      L'équipe 1001mots
    MSG3
  ].freeze

  BETA_TEST_PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGES = [
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

  BETA_TEST_AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGES = [
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

  def initialize(date: Time.zone.today.next_occurring(:friday), send_at: nil)
    @errors = []
    @date = date
    @send_at = send_at
    @groups = []
  end

  def call
    @errors << { service: 'Parent::SendBeforeCallsMessageService', error: 'BETA_TEST_CALLERS_EMAIL is not set' } if ENV['BETA_TEST_CALLERS_EMAIL'].blank?
    return self if @errors.any?

    (1..3).each do |call_index|
      @groups[call_index] = Group.with_calls.where("call#{call_index}_start_date = ?", @date.next_occurring(:monday))
    end

    @groups.each_with_index do |group_list, call_index|
      next if call_index.zero?

      group_list.each do |group|
        handle_group_message(group, call_index)
      end
    end
    self
  end

  def handle_group_message(group, call_index, child_support_ids = [])
    child_supports_with_correct_supporters =
      if child_support_ids.any?
        ChildSupport.where(id: child_support_ids).with_valid_supporter_for_calendly
      else
        group.child_supports.with_valid_supporter_for_calendly
      end

    child_supports_with_previous_calls_ok_or_unfinished =
      child_supports_with_correct_supporters.previous_calls_ok_or_unfinished_before(call_index)

    no_beta_test_child_supports_with_previous_calls_ok_or_unfinished =
      child_supports_with_previous_calls_ok_or_unfinished.where.not(supporter: { email: ENV['BETA_TEST_CALLERS_EMAIL'].split })
    send_before_calls_message(group, no_beta_test_child_supports_with_previous_calls_ok_or_unfinished, NO_BETA_TEST_PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGES[call_index - 1])

    beta_test_child_supports_with_previous_calls_ok_or_unfinished =
      child_supports_with_previous_calls_ok_or_unfinished.where(supporter: { email: ENV['BETA_TEST_CALLERS_EMAIL'].split })
    create_one_off_event_types(beta_test_child_supports_with_previous_calls_ok_or_unfinished, call_index)
    send_before_calls_message(group, beta_test_child_supports_with_previous_calls_ok_or_unfinished, BETA_TEST_PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGES[call_index - 1])

    child_support_with_at_least_one_call_not_ok_and_not_unfinished =
      child_supports_with_correct_supporters.at_least_one_call_not_ok_and_not_unfinished(call_index)
    no_beta_test_child_support_with_at_least_one_call_not_ok_and_not_unfinished =
      child_support_with_at_least_one_call_not_ok_and_not_unfinished.where.not(supporter: { email: ENV['BETA_TEST_CALLERS_EMAIL'].split })
    send_before_calls_message(group, no_beta_test_child_support_with_at_least_one_call_not_ok_and_not_unfinished, NO_BETA_TEST_AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGES[call_index - 1])

    beta_test_child_support_with_at_least_one_call_not_ok_and_not_unfinished =
      child_support_with_at_least_one_call_not_ok_and_not_unfinished.where(supporter: { email: ENV['BETA_TEST_CALLERS_EMAIL'].split })
    create_one_off_event_types(beta_test_child_support_with_at_least_one_call_not_ok_and_not_unfinished, call_index)
    send_before_calls_message(group, beta_test_child_support_with_at_least_one_call_not_ok_and_not_unfinished, BETA_TEST_AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGES[call_index - 1])
  end

  private

  def create_one_off_event_types(child_supports, call_index)
    return if child_supports.empty?

    child_supports.each do |child_support|
      create_one_off_event_type_service = Calendly::CreateOneOffEventTypeService.new(child_support: child_support, call_session: call_index).call
      next if create_one_off_event_type_service.errors.empty?

      @errors << {
        method: 'create_one_off_event_types',
        child_supports: child_supports.map(&:id),
        call_index: call_index,
        error: create_one_off_event_type_service.errors.uniq
      }
    end
  end

  def parent_ids(child_supports)
    return [] if child_supports.empty?

    child_supports.map { |child_support| %W[parent.#{child_support.parent1.id} parent.#{child_support.parent2&.id}] }.flatten.compact.reject { |recipient| recipient == 'parent.' }
  end

  def send_before_calls_message(group, child_supports, message)
    return if child_supports.empty?

    planned_date = (@send_at || @date).strftime('%d-%m-%Y')
    planned_hour = @send_at ? @send_at&.strftime('%H:%M') : '18:00'
    message_service = ProgramMessageService.new(
      planned_date,
      planned_hour,
      parent_ids(child_supports),
      message
    ).call
    return if message_service.errors.empty?

    @errors << {
      method: 'send_before_calls_message',
      group: group.name,
      child_supports: child_supports.map(&:id),
      error: message_service.errors.uniq
    }
  end
end
