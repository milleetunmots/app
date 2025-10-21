class Parent::SendDisengagementWarningBeforeCallsService

  PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGE = [
    <<~MSG1,
      Bonjour,
      C'est le début de votre accompagnement avec l'association 1001mots, qui va vous envoyer des SMS et des livres pour {PRENOM_ENFANT}. {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour vous expliquer comment ça se passe, faire connaissance et discuter avec vous :)
      Pensez à enregistrer son numéro {NUMERO_AIRCALL_ACCOMPAGNANTE}
      A très bientôt !
      L'équipe 1001mots
    MSG1
    <<~MSG2,
      Bonjour,
      Vous avez bien reçu le 1er livre de l’association 1001mots pour {PRENOM_ENFANT} ? {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour en discuter avec vous et vous donner des astuces pour l'utiliser avec {PRENOM_ENFANT} ;)
      Pensez à enregistrer son numéro {NUMERO_AIRCALL_ACCOMPAGNANTE}
      A très bientôt !
      L'équipe 1001mots
    MSG2
    <<~MSG3,
      Bonjour,
      A 1001mots on espère que vous allez bien et {PRENOM_ENFANT} aussi :) {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour prendre des nouvelles, discuter avec vous et vous donner des astuces pour aider {PRENOM_ENFANT} avec son langage.
      A très bientôt !
      L'équipe 1001mots
    MSG3
    <<~MSG4
      Bonjour,
      A 1001mots on espère que vous allez bien et {PRENOM_ENFANT} aussi :) {PRENOM_ACCOMPAGNANTE} va bientôt vous appeler pour discuter avec vous de ce qui intéresse {PRENOM_ENFANT} en ce moment.
      A très bientôt !
      L'équipe 1001mots
    MSG4
  ].freeze

  AT_LEAST_ONE_CALL_NOT_OK_AND_NOT_UNFINISHED_WARNING_MESSAGE = [
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

  attr_reader :errors

  def initialize
    @errors = []
    @date = Time.zone.today
    @groups = []
    4.times do |time|
      @groups << Group.with_calls.where("call#{time}_start_date = ?", @date + 3.day)
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
               .previous_calls_ok_or_unfinished_before(call_index)
               .map { |child_support| "parent.#{child_support.parent1.id}" }
        previous_calls_ok_or_unfinished_warning_service = ProgramMessageService.new(
          @date.strftime('%d-%m-%Y'),
          '19:00',
          parent_with_previous_calls_ok_or_unfinished_ids,
          PREVIOUS_CALLS_OK_OR_UNFINISHED_WARNING_MESSAGE[call_index]
        ).call
        @errors << "Parent::SendDisengagementWarningBeforeCallsService (group: #{group.name}) : #{previous_calls_ok_or_unfinished_warning_service.errors.uniq}" if previous_calls_ok_or_unfinished_warning_service.errors

        parent_with_at_least_one_call_not_ok_and_not_unfinished_ids =
          group.child_supports
               .with_a_child_in_active_group
               .joins(:supporter)
               .where(supporter: { can_send_automatic_sms: true })
               .at_least_one_call_not_ok_and_not_unfinished(call_index)
               .map { |child_support| "parent.#{child_support.parent1.id}" }
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
