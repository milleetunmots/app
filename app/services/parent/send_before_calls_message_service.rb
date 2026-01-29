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
      On espère que vous allez bien et {PRENOM_ENFANT} aussi :){PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour discuter avec vous de ce qui intéresse {PRENOM_ENFANT} en ce moment.
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
        parent_with_previous_calls_ok_or_unfinished_ids =
          group.child_supports
               .with_a_child_in_active_group
               .joins(:supporter)
               .where(supporter: { can_send_automatic_sms: true })
               .where.not(supporter: { aircall_number_id: nil })
               .where.not(supporter: { calendly_user_uri: nil })
               .previous_calls_ok_or_unfinished_before(call_index)
               .map { |child_support| %W[parent.#{child_support.parent1.id} parent.#{child_support.parent2&.id}] }.flatten.compact
        previous_calls_ok_or_unfinished_warning_service = ProgramMessageService.new(
          @date.strftime('%d-%m-%Y'),
          '19:00',
          parent_with_previous_calls_ok_or_unfinished_ids,
          PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGE[call_index]
        ).call
        @errors << "Parent::SendDisengagementWarningBeforeCallsService (group: #{group.name}) : #{previous_calls_ok_or_unfinished_warning_service.errors.uniq}" if previous_calls_ok_or_unfinished_warning_service.errors
        next if call_index.zero?

        parent_with_at_least_one_call_not_ok_and_not_unfinished_ids =
          group.child_supports
               .with_a_child_in_active_group
               .joins(:supporter)
               .where(supporter: { can_send_automatic_sms: true })
               .where.not(supporter: { aircall_number_id: nil })
               .where.not(supporter: { calendly_user_uri: nil })
               .at_least_one_call_not_ok_and_not_unfinished(call_index)
               .map { |child_support| %W[parent.#{child_support.parent1.id} parent.#{child_support.parent2&.id}] }.flatten.compact
        at_least_one_call_not_ok_and_not_unfinished_warning_service = ProgramMessageService.new(
          @date.strftime('%d-%m-%Y'),
          '19:00',
          parent_with_at_least_one_call_not_ok_and_not_unfinished_ids,
          AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGE[call_index - 1]
        ).call
        @errors << "Parent::SendDisengagementWarningBeforeCallsService (group: #{group.name}) : #{at_least_one_call_not_ok_and_not_unfinished_warning_service.errors.uniq}" if at_least_one_call_not_ok_and_not_unfinished_warning_service.errors
      end
    end
    self
  end
end
